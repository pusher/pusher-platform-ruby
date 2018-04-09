require_relative './common'

module PusherPlatform
  class ErrorResponse < Error
    attr_accessor :status, :headers, :description

    def initialize(status, headers, description)
      @status = status
      @headers = headers
      @description = description
    end

    def to_s
      "PusherPlatform::ErrorResponse - status: #{status} description: #{description}"
    end
  end
end
