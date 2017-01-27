require_relative './authenticator'
require_relative './base_client'
require_relative './common'
require_relative './error_response'

module Pusher
  class App
    def initialize(options)
      raise "Invalid app ID" if options[:app_id].nil?
      @app_id = options[:app_id]

      app_key_parts = /^([^:]+):(.+)$/.match(options[:app_key])
      raise "Invalid app key" if app_key_parts.nil?

      @app_key_id = app_key_parts[1]
      @app_key_secret = app_key_parts[2]

      @client = if options[:client]
        options[:client]
      else
        raise "Invalid cluster" if options[:cluster].nil?
        BaseClient.new(host: options[:cluster])
      end

      @authenticator = Authenticator.new(@app_id, @app_key_id, @app_key_secret)
    end

    def request(options)
      options = scope_request_options("apps", options)
      if options[:jwt].nil?
        options = options.merge({ jwt: generate_superuser_jwt() })
      end
      @client.request(options)
    end

    def config_request(options)
      options = scope_request_options("config/apps", options)
      if options[:jwt].nil?
        options = options.merge({ jwt: generate_superuser_jwt() })
      end
      @client.request(options)
    end

    def authenticate(request, options)
      @authenticator.authenticate(request, options)
    end

    private

    def scope_request_options(prefix, options)
      path = "/#{prefix}/#{@app_id}/#{options[:path]}"
        .gsub(/\/+/, "/")
        .gsub(/\/+$/, "")
      options.merge({ path: path })
    end

    def generate_superuser_jwt
      now = Time.now.utc.to_i
      claims = {
        app: @app_id,
        iss: @app_key_id,
        su: true,
        iat: now - 30,   # some leeway for the server
        exp: now + 60*5, # 5 minutes should be enough for a single request
      }
      JWT.encode(claims, @app_key_secret)
    end
  end
end
