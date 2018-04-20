module PusherPlatform
  class AuthenticationResponse
    attr_reader :status, :headers, :body

    def initialize(options)
      @status = options[:status]
      @headers = options[:headers] || {}
      @body = options[:body]
    end

    def to_s
      "PusherPlatform::AuthenticationResponse - status: #{@status} body: #{@body.to_json}"
    end

    def as_json(options = {})
      {
        status: @status,
        headers: @headers,
        body: @body
      }
    end

    def to_json(*options)
      as_json(*options).to_json(*options)
    end

  end
end
