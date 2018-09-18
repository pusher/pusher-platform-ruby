require_relative './error'

module PusherPlatform
  class SDKInfo
    attr_reader :product_name, :version, :language, :platform, :headers

    def initialize(options)
      raise Error.new('No product_name provided to SDKInfo') if options[:product_name].nil?
      raise Error.new('No version provided to SDKInfo') if options[:version].nil?

      @product_name = options[:product_name]
      @version = options[:version]

      @platform = options[:platform] || 'server'
      @language = 'ruby'

      @headers = {
        "X-SDK-Product" => @product_name,
        "X-SDK-Version" => @version,
        "X-SDK-Language" => @language,
        "X-SDK-Platform" => @platform
      }
    end

  end
end
