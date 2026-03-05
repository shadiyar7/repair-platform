module IDocs
  class Client
    # Production environment (external.idocs.kz)
    # Swagger: https://external.idocs.kz/swagger/index.html
    BASE_URL = ENV.fetch('IDOCS_BASE_URL', 'https://external.idocs.kz/api/v1')
    TOKEN    = ENV.fetch('IDOCS_TOKEN', 'eyJhbGciOiJSU0EtT0FFUCIsImVuYyI6IkEyNTZDQkMtSFM1MTIiLCJraWQiOiJCNEVFQjMzNkREMDQ0MzkwM0EyQzQwNzVDMDJGNzg2RTEzRjQ2QUIwIiwidHlwIjoiYXQrand0In0.J1tut9vYW1atAnPjzVLYJFPv1zCvO08nE8JleifMErgKiM87l9fvZQuQrPzcQNoAR2sj4stWK4UAPzVYaL_t79FlF-rafmO3uZ_hfwvprUa-uW2OWwhHnNrdT1HIwY9JZLIHKpwAz9wkDewLw2tVORFUErFi5VAeocwjRbZxU3EJwjcepWu1huMTqMGJpgGLUJP6ICTluqb2Uw3EsyN3E0zzWHWR0nvpq_kdkgQY7sFU1ExeajGXZUU9EzahLUo3ix6axTwWr8JgchQKVftFOTSaI_gwJ8QY8bAk4GqyBGAvfadXrz10dbtEewx2xvhNjKCFVJWIqWwqbEmm1Ldrxg.39E2XhhVaLp3gLxJ8r-dKA.GWPhE-BUrRU1jijujdqSBImUtVOLCEwqIAfSg8pxYJvi2ONJjNulcwOObBVq9zHzRqKMfPZEQvAVuYhnX4ai7a23DMSNLIhIB8KcpC5lMiWL3XYofjeu1Z_3ELFkJBC_NKaKXxpp5F72ATFhoGlkZPrXN2f0Vf1h5OVdEjNiwtCskNE4Zl6AMkGYuu6E6V0pogP1Ens2vOXDWQjXPR2nS1ZEaWRS6e391EECSjDJPxUXFl20dyo3syNoctgqg_f8pp3WW8ZrHuvVgw7u2wcDZ27GqUR03KJK4pom1_0jR8y_k7Obf3FBI-i0ysKabSh4Arz_aeZF0JV_OOzhW0LnD-OpGQWXfVkxnnK8CSiBF2uVPadtlKGdpXvM5Rdf2Z6eYJ3ObArqam2S7t8naQKn8hZYs26CrPWmKMeka0p3l-phzhVX4xOo1FV1TOusN7Bpzae1bO5-EwuohBLAmnwNlA0Ew4ekYfz-gpV2AeDs-x3h1BQ6C3wyvQNIVkS1bXLU35dietVc77Sqbos7ZwJlzm-Vj8oW0WWPYR943imu-TWNg1iVTCTmPG7qG78rFjKjw1k8VqT7X5WjZ5g0jFFPfPcg-U6k0ePmh8fAg_zrCV5UKZXpVkEsAmYSQVPEpZmyeNKHvzIXLx9g6mRvTIh6cP4T9kmFUBJGHOjo3j5qpoR5EOu_xBxKmauCIB561kwWL-K4vGOlad6PTJzWcn8EH-Ba1CaG8zJVz_xDhFo9RSkMmbiUwnOxPPMptToD2A9PwhkMI1CvVCcG9T_YB3eGzda5LVw--o_Pt3fYiGmsVO3x_21rCoIljYxoEa5cFJ0raTQcyws66wuQ4_JeAWMbB94SO4P-_qC03doq3dUStTniWfKIBFj67EvJPUHfw4lcAY8Bbl3PXrPfG6f7kHQntMiZJOWvwDTLbUFW3H-v3mMEFvBqQBWRKkXnZmytgTE30lSC2VGN_Ymn7mldKs0WI_hKYQmdDHxqueVc4-WB_EwboLjIS97w01rt82GMiHBIKfhXE0F74Mxn2qCqRhJRkm05WxoFfvfrBOaiyK3-fHMLWSsex7eOBY2EGkT0JbWXZuurHVQAjSk4lLm7d4K3w_ZyHnwhaJeizGgrTTXpO1-3d42OFRZJuLquGylRerzvlUczfFbpsRUSYgu99Q5asgD5w6Ic8yd4YOVPxO3j2Rfe6VICACkEGUs9POpNh8vyb2UORZ5H1m8cWtnwEHXA0auCUdcduNiO2IlxS3GsauWh9LpfQSMh8M3wF85pFblUNcHChowF71PgyvwzuDSaZcTVTPfQUmn2DOW_be57yc0AoRXZO6fgNXpmsGFodk3ZF7LCWeo5tB735TPtqyb4bW3qcXt9zpX45QMcbTlh4YOwLb-VhvuTxhkpp0ItkxBYdDPNHHRNZjNHPOoVjO6-iRqEkfWDOwYEoyHci50jxU8SXhcQyrzCfAlMSiDDN7uw399mfT2pnF-ceNuY8skaDMdWj3tAuHU2yYJHX5L2fPqPAR6Aj1etN89TBlQYur4AJCt87Zjue1ix2u8RBKDjjJEy4yhf0sbV23RBKTVPepwihe9aeKoAqekW-2CyqIr_9Hj9r8C-O9pWWuwtyZwK3ArhlklqlC1UjPXpdMfHLYrX1LEYbBiAyWoQtJPS48pq8KGZj-xiWLFFVh2Ls_CAqXO-VQ914WwLUX0lYKcajMAAaTiF84NNK6nkoduGQrI_OS4spLGIYD7ddTJacD4MAg0p2v1rUKwd5aNGiYJCGoFC4H4-m3e9Yo-6b4xWBnQkRGb1QVz0cwzVYnZVsIXCyW9pV5Qf9y6guyYvyfDJOnsquxH3rQ6eF3eBisGpuwIfSwcPJQ_bW4Hz76CtZ1Y_bA.M5IzFFX39VabUUoslEOJbqdqPSVVx6FJcZcta_eIrKY')

    # Employee IDs from production iDocs account (retrieved via GET /api/v1/Employees)
    # КОМАНДИРОВ АДИЛЕТ МУРАТОВИЧ — Первый руководитель (Директор)
    DIRECTOR_EMPLOYEE_ID = ENV.fetch('IDOCS_DIRECTOR_EMPLOYEE_ID', '346fd4e7-5e7e-4d54-df9e-08de023003c0')
    # Admin employee ID — not yet retrieved from production, update if needed
    ADMIN_EMPLOYEE_ID    = ENV.fetch('IDOCS_ADMIN_EMPLOYEE_ID', '346fd4e7-5e7e-4d54-df9e-08de023003c0')

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
