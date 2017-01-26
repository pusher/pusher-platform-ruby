require_relative './authenticator'
require_relative './base_client'

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
        raise "Invalid cluster" if options[:cluster]
        BaseClient.new(host: options[:cluster])
      end

      @authenticator = Authenticator.new(@app_id, @app_key_id, @app_key_secret)
    end

    def request(options)
    end

    def config_request(options)
    end

    def authenticate(request, options)
    end
  end
end
