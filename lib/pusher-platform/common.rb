module PusherPlatform
  class Error < ::StandardError
  end

  class ErrorBody
    attr_reader :error, :error_description, :error_uri

    def initialize(options)
      @error = options[:error]
      @error_description = options[:error_description]
      @error_uri = options[:error_uri]
    end

    def as_json(options = {})
      json = {
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
