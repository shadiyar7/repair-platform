module IDocs
  class Client
    # Production environment: https://external.idocs.kz/swagger/index.html
    # API v1 - completely different flow from beta (v3)
    BASE_URL = ENV.fetch('IDOCS_BASE_URL', 'https://external.idocs.kz/api/v1')
    TOKEN    = ENV.fetch('IDOCS_TOKEN', 'eyJhbGciOiJSU0EtT0FFUCIsImVuYyI6IkEyNTZDQkMtSFM1MTIiLCJraWQiOiJCNEVFQjMzNkREMDQ0MzkwM0EyQzQwNzVDMDJGNzg2RTEzRjQ2QUIwIiwidHlwIjoiYXQrand0In0.J1tut9vYW1atAnPjzVLYJFPv1zCvO08nE8JleifMErgKiM87l9fvZQuQrPzcQNoAR2sj4stWK4UAPzVYaL_t79FlF-rafmO3uZ_hfwvprUa-uW2OWwhHnNrdT1HIwY9JZLIHKpwAz9wkDewLw2tVORFUErFi5VAeocwjRbZxU3EJwjcepWu1huMTqMGJpgGLUJP6ICTluqb2Uw3EsyN3E0zzWHWR0nvpq_kdkgQY7sFU1ExeajGXZUU9EzahLUo3ix6axTwWr8JgchQKVftFOTSaI_gwJ8QY8bAk4GqyBGAvfadXrz10dbtEewx2xvhNjKCFVJWIqWwqbEmm1Ldrxg.39E2XhhVaLp3gLxJ8r-dKA.GWPhE-BUrRU1jijujdqSBImUtVOLCEwqIAfSg8pxYJvi2ONJjNulcwOObBVq9zHzRqKMfPZEQvAVuYhnX4ai7a23DMSNLIhIB8KcpC5lMiWL3XYofjeu1Z_3ELFkJBC_NKaKXxpp5F72ATFhoGlkZPrXN2f0Vf1h5OVdEjNiwtCskNE4Zl6AMkGYuu6E6V0pogP1Ens2vOXDWQjXPR2nS1ZEaWRS6e391EECSjDJPxUXFl20dyo3syNoctgqg_f8pp3WW8ZrHuvVgw7u2wcDZ27GqUR03KJK4pom1_0jR8y_k7Obf3FBI-i0ysKabSh4Arz_aeZF0JV_OOzhW0LnD-OpGQWXfVkxnnK8CSiBF2uVPadtlKGdpXvM5Rdf2Z6eYJ3ObArqam2S7t8naQKn8hZYs26CrPWmKMeka0p3l-phzhVX4xOo1FV1TOusN7Bpzae1bO5-EwuohBLAmnwNlA0Ew4ekYfz-gpV2AeDs-x3h1BQ6C3wyvQNIVkS1bXLU35dietVc77Sqbos7ZwJlzm-Vj8oW0WWPYR943imu-TWNg1iVTCTmPG7qG78rFjKjw1k8VqT7X5WjZ5g0jFFPfPcg-U6k0ePmh8fAg_zrCV5UKZXpVkEsAmYSQVPEpZmyeNKHvzIXLx9g6mRvTIh6cP4T9kmFUBJGHOjo3j5qpoR5EOu_xBxKmauCIB561kwWL-K4vGOlad6PTJzWcn8EH-Ba1CaG8zJVz_xDhFo9RSkMmbiUwnOxPPMptToD2A9PwhkMI1CvVCcG9T_YB3eGzda5LVw--o_Pt3fYiGmsVO3x_21rCoIljYxoEa5cFJ0raTQcyws66wuQ4_JeAWMbB94SO4P-_qC03doq3dUStTniWfKIBFj67EvJPUHfw4lcAY8Bbl3PXrPfG6f7kHQntMiZJOWvwDTLbUFW3H-v3mMEFvBqQBWRKkXnZmytgTE30lSC2VGN_Ymn7mldKs0WI_hKYQmdDHxqueVc4-WB_EwboLjIS97w01rt82GMiHBIKfhXE0F74Mxn2qCqRhJRkm05WxoFfvfrBOaiyK3-fHMLWSsex7eOBY2EGkT0JbWXZuurHVQAjSk4lLm7d4K3w_ZyHnwhaJeizGgrTTXpO1-3d42OFRZJuLquGylRerzvlUczfFbpsRUSYgu99Q5asgD5w6Ic8yd4YOVPxO3j2Rfe6VICACkEGUs9POpNh8vyb2UORZ5H1m8cWtnwEHXA0auCUdcduNiO2IlxS3GsauWh9LpfQSMh8M3wF85pFblUNcHChowF71PgyvwzuDSaZcTVTPfQUmn2DOW_be57yc0AoRXZO6fgNXpmsGFodk3ZF7LCWeo5tB735TPtqyb4bW3qcXt9zpX45QMcbTlh4YOwLb-VhvuTxhkpp0ItkxBYdDPNHHRNZjNHPOoVjO6-iRqEkfWDOwYEoyHci50jxU8SXhcQyrzCfAlMSiDDN7uw399mfT2pnF-ceNuY8skaDMdWj3tAuHU2yYJHX5L2fPqPAR6Aj1etN89TBlQYur4AJCt87Zjue1ix2u8RBKDjjJEy4yhf0sbV23RBKTVPepwihe9aeKoAqekW-2CyqIr_9Hj9r8C-O9pWWuwtyZwK3ArhlklqlC1UjPXpdMfHLYrX1LEYbBiAyWoQtJPS48pq8KGZj-xiWLFFVh2Ls_CAqXO-VQ914WwLUX0lYKcajMAAaTiF84NNK6nkoduGQrI_OS4spLGIYD7ddTJacD4MAg0p2v1rUKwd5aNGiYJCGoFC4H4-m3e9Yo-6b4xWBnQkRGb1QVz0cwzVYnZVsIXCyW9pV5Qf9y6guyYvyfDJOnsquxH3rQ6eF3eBisGpuwIfSwcPJQ_bW4Hz76CtZ1Y_bA.M5IzFFX39VabUUoslEOJbqdqPSVVx6FJcZcta_eIrKY')

    # Employee IDs from production iDocs (GET /api/v1/Employees)
    # КОМАНДИРОВ АДИЛЕТ МУРАТОВИЧ — Первый руководитель (Директор)
    DIRECTOR_EMPLOYEE_ID = ENV.fetch('IDOCS_DIRECTOR_EMPLOYEE_ID', '346fd4e7-5e7e-4d54-df9e-08de023003c0')
    ADMIN_EMPLOYEE_ID    = ENV.fetch('IDOCS_ADMIN_EMPLOYEE_ID', '346fd4e7-5e7e-4d54-df9e-08de023003c0')

    def initialize
      @conn = Faraday.new(url: BASE_URL) do |faraday|
        faraday.adapter Faraday.default_adapter
        faraday.headers['Authorization'] = "Bearer #{TOKEN}"
        faraday.headers['Content-Type'] = 'application/json'
        faraday.headers['Accept'] = 'application/json'
      end
    end

    # ─────────────────────────────────────────────────────────────────────────
    # NEW PRODUCTION FLOW (v1)
    #
    # Step 1 (Director side):
    #   POST /api/v1/ExternalDocumentFromFiles
    #     - PDF as base64 in body
    #     - Director signs inline via Steps[].SignBodyAsBase64String
    #     - Recipient BIN + Email in Reciever
    #   Returns: { processKey: "..." } (ASYNC — not document ID!)
    #
    # Step 2 (Poll for document ID):
    #   GET /api/v1/ExternalDocumentFromFiles/{processKey}/WorkflowInfo
    #   Returns document ID once ready
    #
    # Step 3 (Client signs inbox document):
    #   POST /api/v1/ExternalDocuments/SignInboxDocument
    #     - documentId, employeeId, signBodyAsBase64String
    #   Returns: processKey (async again)
    #
    # Step 4 (Get signed PDF):
    #   GET /api/v1/ExternalDocuments/{id}/PrintForm   → PDF bytes
    #   GET /api/v1/ExternalDocuments/{id}/File        → raw file
    # ─────────────────────────────────────────────────────────────────────────

    # Creates document + director signature + sends to client in one request.
    # director_sign_cms: base64-encoded CMS signature from NCALayer
    # client_bin:        receiver BIN (IIN for individuals)
    # client_email:      receiver email
    # Returns: { "processKey" => "..." }
    def create_and_sign_document(pdf_bytes, document_name, document_number, director_sign_cms, client_bin, client_email, is_individual: false)
      pdf_base64   = Base64.strict_encode64(pdf_bytes)
      file_name    = "#{document_number.gsub(/[^a-zA-Z0-9\-_]/, '_')}.pdf"

      payload = {
        DocumentName:         document_name,
        DocumentNumber:       document_number,
        Group:                'PURCHASE',
        Type:                 'GENERAL_EXTERNAL',
        DocumentSum:          nil,
        Reciever: {
          BIN:          client_bin,
          Email:        client_email,
          IsIndividual: is_individual
        },
        FileBodyAsBase64String: pdf_base64,
        FileName:       file_name,
        FileMimeType:   'pdf',
        FileLength:     pdf_bytes.bytesize,
        Steps: [
          {
            Position:            'Директор',
            EmployeeId:           DIRECTOR_EMPLOYEE_ID,
            SignBodyAsBase64String: director_sign_cms,
            SignType:             'CMS'
          }
        ]
      }

      Rails.logger.info "iDocs create_and_sign_document: doc=#{document_name} number=#{document_number}"
      response = @conn.post('ExternalDocumentFromFiles') do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = payload.to_json
      end

      Rails.logger.info "iDocs create_and_sign_document response: status=#{response.status} body=#{response.body.to_s[0..300]}"
      handle_response(response)
    end

    # Poll WorkflowInfo until documentId is available.
    # process_key: returned by create_and_sign_document
    # max_attempts / delay_sec: polling config
    # Returns: document_id string or raises after timeout
    def wait_for_document_id(process_key, max_attempts: 15, delay_sec: 2)
      max_attempts.times do |i|
        info = get_workflow_info(process_key)
        Rails.logger.info "iDocs WorkflowInfo [#{i+1}/#{max_attempts}]: #{info.inspect}"

        doc_id = info.dig('documentId') || info.dig('DocumentId') ||
                 info.dig('data', 'documentId') || info['id']
        return doc_id if doc_id.present?

        # Check for error state
        status = info['status'] || info['Status'] || ''
        raise "iDocs workflow failed with status: #{status}" if status.to_s.downcase.include?('error')

        sleep delay_sec
      end
      raise "iDocs: timed out waiting for documentId for processKey=#{process_key}"
    end

    def get_workflow_info(process_key)
      response = @conn.get("ExternalDocumentFromFiles/#{process_key}/WorkflowInfo")
      Rails.logger.info "iDocs WorkflowInfo response: status=#{response.status} body=#{response.body.to_s[0..500]}"
      handle_response(response)
    end

    # Sign the client's inbox document.
    # doc_id:     the real iDocs document ID (from WorkflowInfo)
    # sign_cms:   base64-encoded CMS from NCALayer (client's NCA key)
    # Returns: process key (async)
    def sign_inbox_document(doc_id, employee_id, sign_cms)
      payload = {
        DocumentId:           doc_id,
        EmployeeId:           employee_id,
        SignBodyAsBase64String: sign_cms,
        SignType:             'CMS'
      }

      Rails.logger.info "iDocs sign_inbox_document: doc=#{doc_id}"
      response = @conn.post('ExternalDocuments/SignInboxDocument') do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = payload.to_json
      end

      Rails.logger.info "iDocs sign_inbox_document response: status=#{response.status} body=#{response.body.to_s[0..500]}"
      handle_response(response)
    end

    def get_workflow_info_external(process_key)
      response = @conn.get("ExternalDocuments/#{process_key}/WorkflowInfo")
      handle_response(response)
    end

    # Get employees list from production account
    def get_employees
      response = @conn.get('Employees')
      handle_response(response)
    end

    # Get the signed PDF print form for a document
    # Returns raw PDF bytes
    def download_print_form(document_id)
      response = @conn.get("ExternalDocuments/#{document_id}/PrintForm") do |req|
        req.headers['Accept'] = 'application/octet-stream, application/pdf, */*'
      end

      if response.success?
        response.body
      else
        Rails.logger.error "IDocs PrintForm Error: #{response.status} - #{response.body}"
        raise "IDocs API Error (PrintForm): #{response.status} - #{response.body}"
      end
    end

    # Get the raw file(s) for a document
    def download_file(document_id)
      response = @conn.get("ExternalDocuments/#{document_id}/File") do |req|
        req.headers['Accept'] = 'application/octet-stream, */*'
      end

      if response.success?
        response.body
      else
        Rails.logger.error "IDocs File Error: #{response.status} - #{response.body}"
        raise "IDocs API Error (File): #{response.status} - #{response.body}"
      end
    end

    # Try to get the best available PDF (PrintForm first, File fallback)
    def get_best_pdf(document_id)
      download_print_form(document_id)
    rescue => e
      Rails.logger.warn "IDocs: PrintForm failed (#{e.message}), trying File fallback"
      download_file(document_id)
    end

    # Get current user / account info
    def get_current_user
      response = @conn.get('Account/Info')
      handle_response(response)
    rescue => e
      { error: e.message }
    end

    private

    def handle_response(response)
      if response.success?
        body = response.body.to_s.strip
        return {} if body.empty?
        begin
          JSON.parse(body)
        rescue JSON::ParserError
          { 'raw' => body }
        end
      else
        error_msg = response.body.to_s
        # iDocs sometimes returns raw ASP.NET 500 HTML pages instead of JSON
        if error_msg.include?('<!DOCTYPE html>') && error_msg.include?('titleerror')
          title = error_msg.match(/<div class="titleerror">(.*?)<\/div>/)&.captures&.first
          stack = error_msg.match(/<pre class="rawExceptionStackTrace">(.*?)<\/pre>/m)&.captures&.first
          error_msg = "iDocs Internal Server Error: #{title || 'Unknown HTML Error'}. Stack: #{(stack || '')[0..200]}"
        end
        Rails.logger.error "IDocs API Error: #{response.status} - #{error_msg[0..500]}"
        raise "IDocs API Error: #{response.status} - #{error_msg[0..500]}"
      end
    end
  end
end
