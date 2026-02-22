module IDocs
  class Client
    # Beta environment (working)
    BASE_URL = 'https://beta-ext-edo-integration.idocs.kz/api/v3'

    # Real EmployeeIDs retrieved from company-employees API (2026-02-21)
    # КОМАНДИРОВ АДИЛЕТ МУРАТОВИЧ — Первый руководитель (Директор)
    DIRECTOR_EMPLOYEE_ID = '08e9f2df-1b6d-447d-3db0-08de6cc71a03'
    # АЛАХАН ШАДИЯР БОЛАТҰЛЫ — Разработчик / Админ
    ADMIN_EMPLOYEE_ID = '5477bb14-63b0-4545-deca-08de6e1521ce'

    # Token provided by idocs manager for beta/test environment
    TOKEN = "eyJhbGciOiJSU0EtT0FFUCIsImVuYyI6IkEyNTZDQkMtSFM1MTIiLCJraWQiOiJCNEVFQjMzNkREMDQ0MzkwM0EyQzQwNzVDMDJGNzg2RTEzRjQ2QUIwIiwidHlwIjoiYXQrand0In0.gr1EOjUJcgj_ek6BXjK2UjKyDdtrqpghe9hrjQraxgY_9oUNf6-_yXfbpAvZoixc80V5Cn25b0F3C0OfwdZSJ56Vn_1J3KQoMFs2lMTEGAvcXw5BGZ3YKOET3DwUD2PzrowCQR4j8QV5Wsclv-D6xFQJ6NyNKKDQoNlJjStjPRRT8IAcSxQQnA7kYdL47HNm6TYWG636pstdhv6SUXDowiLNT-V5cd3oK5dRdEkvTrd3CzbB-aZqwnlPZBCIF15oGtNJ8Ugaq5coOpmFiH1OB0h8HEjMPvKIIy-Gji4LcYLAZi7mfw9EKtqRVfxEstrGR8XOTfGydckSEiXgmgmekQ.H0b7LoorkVAibU9d4uaqnA.zJP_4tyDWnidT3_-AM2kbemQbPO8lAGa0tM7xyevrjm8FIdfXqJdM5fqC0RVbx1lvGq8dd7o5mkBR8NQ7ROS3YFiSCMF8EeAhus5CP1uIVICUlgJ-_PQpR5QoEG2M6dh4ntfyGNOJgjIxwDf-V63cOo8J3WAAX8kfsWwnaMD8WwvyhMFreuV4TZ_2YIMWHEfJHGPeOPakGP3vlsWCI0_FQtSGwNl1YwLYkvcOiRWNprvKNeEf7bBS5arzKZVQVbvV3o-dr9TFwro-Cox4Wmii1Rk6w6w6g6gVPFuysJGczupj9vJX80iuAKRCvjdJxNhgwITbU7bxEVL5pPNg9trL158cx1j1i9Lfmv9nZK4TS7Xkq5UH7eSjLlzlq5aBYFwqZWMlYKTUBTE1i2I1lgo4BuHIjQQaJsqMYJodgnefcLBnPsnPlyMnJp4756_oKG5d7nFC2HRPSEWE-enQYm6tsePS6r3qbyJG8C-ITCWSGlYKXx8blDeRDAwclI0TGhDQiZNXu666vg_PvQtT2OkfVuzrtHcAS5ajbz5PUN9a7IzF0tiLGUKFFy_ezkMtyscjhVdKPU5DSrV7kZsRrFAovEa2vNyxBK5kgT9-eB7f7Usi49iAIrx8qSEOpm2fShVR7IKmQEIDNq1jw3V_vWWYlPgquJFQscxNfP25N4wCJWSIwjpAglAWke8G0V6mGjJMDDZXsRQ7wOFKbMqUa8seKjPjwjY1xtkDTFEfkmbPJIA6OkGHsecon6pLzhu92HD6v9qlIF0I3LFI4a0AVu8yKhKC07r5MIwAvtp0VuSV-jMulDtS8fU40KIjwNS5WaGRhDIFobZEUjcNeneVHXoj7V3p0_c1EEN8MyNoRO0Moxg3XqYq4e-i3eSKOkgMxNIGjk6bvY5TtNmOz2M_47kuo--Oc6UWyIbx0QBrQ0YnMtgRcvjnjqY7M_wH_yFAB9LhKaetLLpcFH8g03hnTNxDaMtD02IF4ojxSxqSmptigWtF91jkVJQdpUhbRZEYNXDynxFa9H9u14KiMW6aiNGD8MgpCdeLvFWDHv8Vu-_cc9jB1Fq_lrrrj8J3c_F5neQR6SrmqImtQXXzVHjl5_G0wW0QPYsQ_6PckWkczbGxnwhpZjoY2JH6UUrQIF4Qa4FSTP4ASROljrQh_Y-s6KgiY2L1voscelc2hiEPwimu-2vlwf23GF6tzDTHsn2CanF417I2vuky3A8IXZy_ltJQdxms8Zk-HE5h5zE43-4EJ1r0oFTLP0x_cvp5AJGwS6fn_SLF2_FgqHa-JIE8JzaurdzwlGsZUo6v8xTUNYZxg6RO8-F8Xa6sS0Ei7dcTupPukKPNz1mNC1QqWEz4IWt4peiR0RPhw5TpbtCkZu_UX7bVTKUnNI7gL4dzpx2_rmZA6U3Gym5h70kiHJjKhAJFXQ2PTe7spSlCvVux4QBgBxUOYPAAvrCg1-TRKBE44Ib2D8hfcKMYxeWu5bARg1yGM8xpOe5wkxPsY4Ng3pkf4a4SQMSE6QFBIQA_-X266Gp0_NfUhtQ_tuEBmXNCVzZ09Gv0voANWkJPdmjgli_kykYXXKcCcakDRoanMWYLVRfj0TREOa1yO7V24q5zUq97P0ULTTZeUyocYiYqNBVBg4aPEAaK0VOQmFg6OxDZow6sWVNS_zo2CdaWZJWw_JOMxFygFHkA4CWUAk-TcUpND4h2wCxje9vPg29RFw4ahBst2AUIZarKymOq_-ms4h_ZrTzYGXoEkdiVDKDfe7T_lgWMhDVZdpHjnDlwG1EmA-xOGFm2-_LG-G4uPQSZfWpAri-Q9wGsZZC4gZnNqIs74R4VOiOeIUe1dxuLvmp_9RWwyJPbE2NWIHJcSxpegYsxFEuiE6vQP8yDq-wC7XpPZo.dU5mJIBgFbb9_2xHmdSqi6JR-WVmYmwRs7-1p0wA_9Q"

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
        employeeId: employee_id,
        signatureBinaryContents: [
          { blobId: signature_blob_id }
        ],
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
                    nodes: [
                        {
                            order: 0,
                            counterpartyBin: client_bin,
                            comment: "Please sign this document",
                            isIndividual: false,
                            counterpartyEmails: [client_email],
                            requiredActionType: "Signature" # Guessing enum
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
