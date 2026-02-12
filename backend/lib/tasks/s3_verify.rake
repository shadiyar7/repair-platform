namespace :s3 do
  desc "Verify Connection to Yandex Object Storage (S3)"
  task verify: :environment do
    require 'aws-sdk-s3'
    require 'active_storage'

    puts "=== Yandex S3 Verification Task ==="
    puts "Environment: #{Rails.env}"
    puts "Time: #{Time.now}"

    # Configuration
    access_key_id = ENV['YANDEX_ACCESS_KEY_ID']
    bucket_name = ENV['YANDEX_BUCKET']
    region = 'ru-central1'
    endpoint = 'https://storage.yandexcloud.kz'

    # Check presence of ENV variables
    puts "\n[1/3] Checking Environment Variables..."
    missing_vars = []
    missing_vars << 'YANDEX_ACCESS_KEY_ID' if access_key_id.blank?
    missing_vars << 'YANDEX_SECRET_ACCESS_KEY' if ENV['YANDEX_SECRET_ACCESS_KEY'].blank?
    missing_vars << 'YANDEX_BUCKET' if bucket_name.blank?

    if missing_vars.any?
      puts "❌ FAILED: Missing environment variables: #{missing_vars.join(', ')}"
      exit 1
    else
      puts "✅ Environment variables present."
    end
    
    puts "  Endpoint: #{endpoint}"
    puts "  Region: #{region}"
    puts "  Bucket: #{bucket_name}"
    puts "  Access Key: #{access_key_id.to_s[0..5]}... (Length: #{access_key_id.to_s.length})"

    # SDK Verification
    puts "\n[2/3] Testing Direct SDK Connection..."
    begin
      client = Aws::S3::Client.new(
        access_key_id: access_key_id,
        secret_access_key: ENV['YANDEX_SECRET_ACCESS_KEY'],
        region: region,
        endpoint: endpoint,
        force_path_style: true
      )

      resp = client.list_buckets
      buckets = resp.buckets.map(&:name)
      if buckets.include?(bucket_name)
        puts "✅ Auth OK. Bucket '#{bucket_name}' found in list."
      else
        puts "⚠️ Auth OK, but bucket '#{bucket_name}' NOT found in list. Available: #{buckets.join(', ')}"
      end

      # Upload Test File
      client.put_object(
        bucket: bucket_name,
        key: "verification_#{Rails.env}.txt",
        body: "Hello from Repair Platform (#{Rails.env}) verification task at #{Time.now}"
      )
      puts "✅ Test file 'verification_#{Rails.env}.txt' uploaded via SDK."

    rescue => e
      puts "❌ SDK Error: #{e.class} - #{e.message}"
    end

    # ActiveStorage Verification
    puts "\n[3/3] Testing ActiveStorage Integration..."
    begin
      service_name = Rails.configuration.active_storage.service
      puts "  ActiveStorage Service Name: #{service_name}"
      
      # Since we might be in production using :local temporarily, we check the actual service class
      service = ActiveStorage::Blob.service
      puts "  Actual Service Class: #{service.class.name}"

      if service.is_a?(ActiveStorage::Service::S3Service)
        blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new("ActiveStorage verification content"),
          filename: "as_verify_#{Rails.env}.txt",
          content_type: 'text/plain'
        )
        puts "✅ ActiveStorage Blob created: #{blob.key}"
        puts "  URL: #{blob.url}"
      elsif service.is_a?(ActiveStorage::Service::DiskService)
         puts "⚠️ ActiveStorage is currently using DiskService (Local). Uploading locally..."
         blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new("Local verification content"),
          filename: "local_verify_#{Rails.env}.txt",
          content_type: 'text/plain'
        )
        puts "✅ Local Blob created: #{blob.key} (Stored on Disk)"
      else
         puts "ℹ️  ActiveStorage is using #{service.class.name}."
      end

    rescue => e
      puts "❌ ActiveStorage Error: #{e.class} - #{e.message}"
    end

    puts "\n=== Verification Finished ==="
  end
end
