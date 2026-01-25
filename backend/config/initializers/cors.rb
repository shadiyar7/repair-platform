# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Allow localhost, specific FRONTEND_URL, AND any Vercel deployment (preview or prod)
    # Allow ALL origins (1C, Partners, Mobile, Web)
    # We use a block to allow 'credentials: true' to work with any origin
    origins { |source, env| true }

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ['Authorization'],
      credentials: true
  end
end
