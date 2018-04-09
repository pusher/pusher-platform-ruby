require_relative './common'

module PusherPlatform
  class ErrorWithStatus < Error
    attr_accessor :status, :description

    def initialize(status, description)
      @status = status
      @description = description
    end

    def to_s
      "PusherPlatform::ErrorWithStatus - status: #{status} description: #{description}"
    end
  end
end
