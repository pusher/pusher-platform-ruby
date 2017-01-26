module Pusher
  class ErrorResponse < Error
    attr_accessor :status, :headers, :body

    def initialize(status, headers, body)
      @status = status
      @headers = headers
      @body = body
    end

    def to_s
      "Pusher::ErrorResponse: #{status} #{body}"
    end
  end
end
