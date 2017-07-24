require 'excon'
require 'json'

module Pusher
  class BaseClient
    def initialize(options)
      raise "Unspecified host" if options[:host].nil?
      port_string = options[:port] || ''
      host_string = "https://#{options[:host]}#{port_string}"
      @connection = Excon.new(host_string)

      @instance_id = options[:instance_id]
      @service_name = options[:service_name]
      @service_version = options[:service_version]
    end

    def request(options)
      raise "Unspecified request method" if options[:method].nil?
      raise "Unspecified request path" if options[:path].nil?

      headers = if options[:headers]
        options[:headers].dup
      else
        {}
      end

      if options[:jwt]
        headers["Authorization"] = "Bearer #{options[:jwt]}"
      end

      path = "services/#{@service_name}/#{@service_version}/#{@instance_id}/#{options[:path]}"
      body = options[:body].any? ? options[:body].to_json : nil

      response = @connection.request(
        method: options[:method],
        path: sanitise_path(path),
        headers: headers,
        body: body,
      )

      if response.status >= 200 && response.status <= 299
        return response
      elsif response.status >= 300 && response.status <= 399
        raise "unsupported redirect response: #{response.status}"
      elsif response.status >= 400 && response.status <= 599
        error_description = begin
          JSON.parse(response.body)
        rescue
          response.body
        end
        raise ErrorResponse.new(response.status, response.headers, error_description)
      else
        raise "unsupported response code: #{response.status}"
      end
    end

    private

    def sanitise_path(path)
      path.gsub(/\/+/, "/").gsub(/\/+$/, "")
    end
  end
end
