require 'excon'
require 'json'
require_relative './sdk_info'
require_relative './error_response'
require_relative './error'

module PusherPlatform
  class BaseClient
    def initialize(options)
      raise PusherPlatform::Error.new("Unspecified host") if options[:host].nil?
      raise PusherPlatform::Error.new("Unspecified sdk_info") if options[:sdk_info].nil?
      port_string = options[:port] || ''
      host_string = "https://#{options[:host]}#{port_string}"
      @connection = Excon.new(host_string)

      @instance_id = options[:instance_id]
      @service_name = options[:service_name]
      @service_version = options[:service_version]

      @sdk_info = options[:sdk_info]
    end

    def request(options)
      raise PusherPlatform::Error.new("Unspecified request method") if options[:method].nil?
      raise PusherPlatform::Error.new("Unspecified request path") if options[:path].nil?

      headers = @sdk_info.headers
      headers.merge(options[:headers].dup) if options[:headers]

      if options[:jwt]
        headers["Authorization"] = "Bearer #{options[:jwt]}"
      end

      path = "services/#{@service_name}/#{@service_version}/#{@instance_id}/#{options[:path]}"
      body = unless options[:body].nil?
        options[:body].to_json
      end

      response = @connection.request(
        method: options[:method],
        path: sanitise_path(path),
        headers: headers,
        body: body,
        query: options[:query]
      )

      if response.status >= 200 && response.status <= 299
        return response
      elsif response.status >= 300 && response.status <= 399
        raise PusherPlatform::Error.new("Unsupported redirect response: #{response.status}")
      elsif response.status >= 400 && response.status <= 599
        error = begin
          JSON.parse(response.body)
        rescue
          response.body
        end
        error_res_opts = {
          status: response.status,
          headers: response.headers,
          error: error["error"],
          error_description: error["error_description"],
          error_uri: error["error_uri"]
        }
        raise ErrorResponse.new(error_res_opts)
      else
        raise PusherPlatform::Error.new("Unsupported response code: #{response.status}")
      end
    end

    private

    def sanitise_path(path)
      path.gsub(/\/+/, "/").gsub(/\/+$/, "")
    end
  end
end
