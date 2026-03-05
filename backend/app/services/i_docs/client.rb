module IDocs
  class Client
    # URL and token are configurable via environment variables (set in Render dashboard)
    # IDOCS_BASE_URL: Production = 'https://ext-edo-integration.idocs.kz/api/v3'
    #                 Beta       = 'https://beta-ext-edo-integration.idocs.kz/api/v3'
    # IDOCS_TOKEN: Bearer token from iDocs account manager
    BASE_URL = ENV.fetch('IDOCS_BASE_URL', 'https://beta-ext-edo-integration.idocs.kz/api/v3')
    TOKEN    = ENV.fetch('IDOCS_TOKEN', nil)

    # Real EmployeeIDs retrieved from company-employees API
    # These will differ between beta and production environments — set via ENV as well
    DIRECTOR_EMPLOYEE_ID = ENV.fetch('IDOCS_DIRECTOR_EMPLOYEE_ID', '08e9f2df-1b6d-447d-3db0-08de6cc71a03')
    ADMIN_EMPLOYEE_ID    = ENV.fetch('IDOCS_ADMIN_EMPLOYEE_ID', '5477bb14-63b0-4545-deca-08de6e1521ce')

    def initialize
      # JSON connection — for all API calls (create_document, save_signature, etc.)
      @conn = Faraday.new(url: BASE_URL) do |faraday|
        faraday.adapter Faraday.default_adapter
        faraday.headers['Authorization'] = "Bearer #{TOKEN}"
        faraday.headers['Content-Type'] = 'application/json'
        faraday.headers['Accept'] = 'application/json'
      end

      # Multipart connection — for file uploads only
      @upload_conn = Faraday.new(url: BASE_URL) do |faraday|
        faraday.request :multipart
        faraday.request :url_encoded
        faraday.adapter Faraday.default_adapter
        faraday.headers['Authorization'] = "Bearer #{TOKEN}"
        faraday.headers['Accept'] = 'application/json'
      end
    end

    # Test method to check token validity
    def get_current_user
      # Trying to guess the endpoint for user info. 
      # Common patterns: /users/current, /users/me, /employees/current
      # Based on iDocs docs structure, it helps to find "EmployeeID".
      
      # Let's try to get profile/user info. 
      # Since I don't have the full Swagger spec, I will try a safe GET request.
      # If this fails, we'll see 404.
      
      response = @conn.get('users/current') 
      if response.status == 404
         response = @conn.get('employees/current')
      end

      if response.success?
        JSON.parse(response.body)
      else
        { error: response.status, body: response.body }
      end
    rescue => e
      { error: e.message }
    end

    def upload_file(file_path)
      payload = {
        documentContent: Faraday::UploadIO.new(file_path, 'application/pdf')
      }
      # Use @upload_conn (multipart) for file upload
      response = @upload_conn.post('sync/blobs/document-content', payload)
      handle_response(response)
    end

    def create_document(metadata, blob_id)
      # Metadata: { name: "", number: "", date: unix_timestamp (int), group: DocumentGroupType enum, author_id: uuid }
      payload = {
        documentMetadata: {
          documentName: metadata[:name],
          documentNumber: metadata[:number],
          documentDate: metadata[:date],      # Unix timestamp integer per iDocs API docs
          documentGroup: metadata[:group],    # Required enum: Purchase/Legal/Accounting/Financial/HR/etc
          documentAuthorEmployeeId: metadata[:author_id]
        },
        documentBinaryContents: [
          { blobId: blob_id }
        ]
      }

      Rails.logger.info "iDocs create_document full payload: #{payload.to_json}"
      response = @conn.post('sync/external/outbox/document/create') do |req|
        req.headers['Content-Type'] = 'application/json'
        req.headers['Accept'] = 'application/json'
        req.body = payload.to_json
      end
      
      handle_response(response)
    end

    def get_content_to_sign(document_id, employee_id)
      payload = {
        documentId: document_id,
        signedByEmployeeId: employee_id
      }

      response = @conn.post('sync/external/outbox/signature/content-to-sign/generate') do |req|
        req.headers['Content-Type'] = 'application/json'
        req.headers['Accept'] = 'application/json'
        req.body = payload.to_json
      end
      handle_response(response)
    end

    # Download the binary content-to-sign file from iDocs downloadLink
    # Returns raw bytes (to be base64-encoded before sending to NCALayer)
    # Uses Net::HTTP directly because Faraday normalizes double slashes in URLs
    # However, we also normalize double slashes manually to ensure compatibility
    def download_sign_content(download_link)
      require 'net/http'
      
      # iDocs returns something like .../download//UUID
      # Some environments fail on the double slash. Let's normalize it to single slash.
      # But keep the double slash in https://
      normalized_link = download_link.gsub(%r{([^:])//}, '\1/')
      
      uri = URI.parse(normalized_link)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')

      request = Net::HTTP::Get.new(uri.request_uri)
      request['Authorization'] = "Bearer #{TOKEN}"
      request['Accept'] = '*/*'

      Rails.logger.info "iDocs downloading sign content from (normalized): #{normalized_link}"
      response = http.request(request)
      Rails.logger.info "iDocs download response: status=#{response.code}, body_size=#{response.body&.bytesize}"

      if response.code.to_i != 200
        # If normalized failed, try the original link as a fallback
        Rails.logger.warn "Normalized link failed (404), retrying original: #{download_link}"
        uri = URI.parse(download_link)
        request = Net::HTTP::Get.new(uri.request_uri)
        request['Authorization'] = "Bearer #{TOKEN}"
        request['Accept'] = '*/*'
        response = http.request(request)
        Rails.logger.info "iDocs fallback download response: status=#{response.code}, body_size=#{response.body&.bytesize}"
      end

      raise "Failed to download sign content after retry: #{response.code} #{response.message}" unless response.code.to_i == 200
      response.body
    end

    def upload_signature(signature_data)
      # Signature data from NCALayer is usually a CMS (binary/base64).
      # If it's base64 string, we might need to decode it or send as file.
      # The endpoint `sync/blobs/document-signature-content` expects multipart form data with file.
      
      # We'll need to save the signature to a temp file first.
      temp_file = Tempfile.new(['signature', '.cms'])
      temp_file.binmode
      temp_file.write(Base64.decode64(signature_data)) # Assuming signature_data is Base64 from frontend
      temp_file.rewind

      payload = {
        signatureContent: Faraday::UploadIO.new(temp_file.path, 'application/octet-stream')
      }
      
      response = @upload_conn.post('sync/blobs/document-signature-content', payload) do |req|
        req.headers['Accept'] = 'text/plain'
      end
      temp_file.close
      temp_file.unlink
      
      handle_response(response)
    end

    def save_signature(document_id, employee_id, signature_blob_id, idempotency_ticket = nil)
      payload = {
        documentId: document_id,
        signedByEmployeeId: employee_id,
        signatureBinaryContent: {
          blobId: signature_blob_id
        },
        idempotencyTicket: idempotency_ticket || SecureRandom.uuid
      }

      Rails.logger.info "iDocs save_signature payload: #{payload.to_json}"
      response = @conn.post('sync/external/outbox/signature/quick-sign/save') do |req|
        req.headers['Content-Type'] = 'application/json'
        req.headers['Accept'] = 'application/json'
        req.body = payload.to_json
      end

      handle_response(response)
    end

    def create_quick_route(document_id, sender_employee_id, client_bin, client_email)
        payload = {
            documentId: document_id,
            employeeId: sender_employee_id,
            route: {
                external: {
                    isSenderPayer: true,
                    isSignRequiredBySender: true,
                    nodes: [
                        {
                            order: 0,
                            counterpartyBin: client_bin,
                            comment: "Please sign this document",
                            isIndividual: false,
                            counterpartyEmails: [client_email],
                            isSignRequiredByCounterparty: true
                        }
                    ]
                }
            }
        }

        response = @conn.post('sync/external/outbox/route/quick-route/create') do |req|
            req.headers['Content-Type'] = 'application/json'
            req.headers['Accept'] = 'application/json'
            req.body = payload.to_json
        end

        Rails.logger.info "iDocs create_quick_route response: status=#{response.status}, body=#{response.body.inspect}"
        handle_response(response)
    end

    def download_print_form(document_id)
      response = @conn.get("sync/single/document/GetDocumentPrintFormByDocumentId/#{document_id}")
      
      if response.success?
        response.body
      else
        Rails.logger.error "IDocs API Error (Download Print Form): #{response.status} - #{response.body}"
        raise "IDocs API Error (Download Print Form): #{response.status} - #{response.body}"
      end
    end

    def download_archive(document_id)
      response = @conn.get("sync/single/document/GetDocumentArchiveByDocumentId/#{document_id}")
      
      if response.success?
        response.body
      else
        Rails.logger.error "IDocs API Error (Download Archive): #{response.status} - #{response.body}"
        raise "IDocs API Error (Download Archive): #{response.status} - #{response.body}"
      end
    end

    def get_best_pdf(document_id)
      begin
        return download_print_form(document_id)
      rescue => e
        Rails.logger.warn "Failed to get print form: #{e.message}. Trying archive fallback..."
        
        # Fallback to Archive
        require 'zip'
        zip_data = download_archive(document_id)
        
        pdf_content = nil
        Zip::File.open_buffer(zip_data) do |zip_file|
          # Try to find a PDF
          pdf_entry = zip_file.glob('*.pdf').first
          if pdf_entry
            pdf_content = pdf_entry.get_input_stream.read
          end
        end
        
        if pdf_content
          return pdf_content
        else
          raise "No PDF found in the document archive"
        end
      end
    end

    def get_document_status(document_id)
      response = @conn.get("sync/single/document/GetDocumentStatusByDocumentId/#{document_id}")
      Rails.logger.info "iDocs get_document_status response: status=#{response.status}, body=#{response.body.inspect}"
      handle_response(response)
    end

    private

    def handle_response(response)
      if response.success?
        body = response.body.to_s.strip
        return {} if body.empty?          # some endpoints return 200 with empty body
        begin
          JSON.parse(body)
        rescue JSON::ParserError
          # Some endpoints return plain text (e.g. a UUID or status string)
          { "raw" => body }
        end
      else
        Rails.logger.error "IDocs API Error: #{response.status} - #{response.body}"
        raise "IDocs API Error: #{response.status} - #{response.body}"
      end
    end
  end
end
