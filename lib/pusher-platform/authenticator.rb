require 'jwt'
require 'rack'
require_relative './error_response'

module PusherPlatform
  TOKEN_EXPIRY = 24*60*60

  class Authenticator
    def initialize(instance_id, key_id, key_secret)
      @instance_id = instance_id
      @key_id = key_id
      @key_secret = key_secret
    end

    def authenticate(auth_payload, options)
      authenticate_based_on_grant_type(auth_payload, options)
    end

    def authenticate_with_request(request, options)
      auth_data = Rack::Utils.parse_nested_query request.body.read
      authenticate_based_on_grant_type(auth_data, options)
    end

    def generate_access_token(options)
      now = Time.now.utc.to_i

      claims = {
        instance: @instance_id,
        iss: "api_keys/#{@key_id}",
        iat: now,
        exp: now + TOKEN_EXPIRY
      }

      claims.merge!({ sub: options[:user_id] }) unless options[:user_id].nil?
      claims.merge!({ su: true }) if options[:su]

      {
        token: JWT.encode(claims, @key_secret, 'HS256'),
        expires_in: TOKEN_EXPIRY
      }
    end

    private

    def authenticate_based_on_grant_type(auth_data, options)
      grant_type = auth_data['grant_type'] || auth_data[:grant_type]

      if grant_type == "client_credentials"
        return authenticate_with_client_credentials(options)
      elsif grant_type == "refresh_token"
        refresh_token = auth_data['refresh_token'] || auth_data[:refresh_token]
        return authenticate_with_refresh_token(refresh_token, options)
      else
        err = ErrorResponse.new({
          status: 401,
          error: 'invalid_grant_type',
          error_description: "Unsupported grant_type #{grant_type}"
        })
        return err
      end
    end

    def authenticate_with_client_credentials(options)
      return new_token_pair(options)
    end

    def authenticate_with_refresh_token(refresh_token, options)
      old_refresh_token = begin
        JWT.decode(refresh_token, @key_secret, true, {
          iss: "api_keys/#{@key_id}",
          verify_iss: true,
        }).first
      rescue => e
        error_description = if e.is_a?(JWT::InvalidIssuerError)
          "Refresh token issuer is invalid"
        elsif e.is_a?(JWT::ImmatureSignature)
          "Refresh token is not valid yet"
        elsif e.is_a?(JWT::ExpiredSignature)
          "Refresh tokan has expired"
        else
          "Refresh token is invalid"
        end

        err = ErrorResponse.new({
          status: 401,
          error: 'invalid_refresh_token',
          error_description: error_description
        })
        return err
      end

      if old_refresh_token["refresh"] != true
        err = ErrorResponse.new({
          status: 401,
          error: 'invalid_refresh_token',
          error_description: "Refresh token does not have a refresh claim"
        })
        return err
      end

      if options[:user_id] != old_refresh_token["sub"]
        return ErrorResponse.new(401, "refresh token has an invalid user id")
      end

      return new_token_pair(options)
    end

    # Creates a payload dictionary made out of access and refresh token pair and TTL for the access token.
    #
    # @param user_id [String] optional id of the user, ignore for anonymous users
    # @return [Hash] Payload as a hash
    def new_token_pair(options)
      access_token = generate_access_token(options)[:token]
      refresh_token = generate_refresh_token(options)[:token]
      {
        access_token: access_token,
        token_type: "bearer",
        expires_in: TOKEN_EXPIRY,
        refresh_token: refresh_token,
      }
    end

    def generate_refresh_token(options)
      now = Time.now.utc.to_i

      claims = {
        instance: @instance_id,
        iss: "api_keys/#{@key_id}",
        iat: now,
        refresh: true,
        sub: options[:user_id],
      }

      { token: JWT.encode(claims, @key_secret, 'HS256') }
    end
  end
end
