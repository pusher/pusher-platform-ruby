require_relative './authenticator'
require_relative './base_client'
require_relative './common'
require_relative './error_response'

module Pusher

  HOST_BASE = 'pusherplatform.io'

  class Instance
    def initialize(options)
      raise "No instance provided" if options[:instance].nil?
      raise "No service name provided" if options[:service_name].nil?
      raise "No service version provided" if options[:service_version].nil?
      instance = options[:instance]
      @service_name = options[:service_name]
      @service_version = options[:service_version]

      key_parts = options[:key].match(/^([^:]+):(.+)$/)
      raise "Invalid key" if key_parts.nil?

      @key_id = key_parts[1]
      @key_secret = key_parts[2]

      split_instance = instance.split(':')

      @platform_version = split_instance[0]
      @cluster = split_instance[1]
      @instance_id = split_instance[2]

      @client = if options[:client]
        options[:client]
      else
        BaseClient.new(
          host: options[:host] || "#{@cluster}.#{HOST_BASE}",
          port: options[:port],
          instance_id: @instance_id,
          service_name: @service_name,
          service_version: @service_version
        )
      end

      @authenticator = Authenticator.new(@instance_id, @key_id, @key_secret)
    end

    def request(options)
      options = scope_request_options(options)
      if options[:jwt].nil?
        options = options.merge(
          { jwt: @authenticator.generate_access_token({ su: true })[:token] }
        )
      end
      @client.request(options)
    end

    def authenticate(request, options)
      @authenticator.authenticate(request, options)
    end

    def generate_access_token(options)
      @authenticator.generate_access_token(options)
    end

    private

    def scope_request_options(options)
      path = options[:path]
        .gsub(/\/+/, "/")
        .gsub(/\/+$/, "")
      options.merge({ path: path })
    end

  end
end
