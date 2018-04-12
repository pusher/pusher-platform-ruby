require_relative './common'

module PusherPlatform
  class ErrorResponse < Error
    attr_reader :status, :headers, :error_description, :error, :error_uri

    def initialize(options)
      @status = options[:status]
      @headers = options[:headers] || {}
      @error = options[:error]
      @error_description = options[:error_description]
      @error_uri = options[:error_uri]
    end

    def to_s
      "PusherPlatform::ErrorResponse - status: #{@status} description: #{@error_description}"
    end

    def as_json(options = {})
      json = {
        status: @status,
        headers: @headers,
        error: @error,
        error_description: @error_description,
      }
      json[:error_uri] = @error_uri unless @error_uri.nil?
      json
    end

    def to_json(*options)
      as_json(*options).to_json(*options)
    end

  end
end
