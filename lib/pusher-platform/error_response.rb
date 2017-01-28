module Pusher
  class ErrorResponse < Error
    attr_accessor :status, :headers, :description

    def initialize(status, headers, description)
      @status = status
      @headers = headers
      @description = description
    end

    def to_s
      "Pusher::ErrorResponse: #{status} #{description}"
    end
  end
end
