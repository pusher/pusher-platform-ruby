require 'jwt'
require_relative './common'
require_relative './authentication_response'
require_relative './rack_query_parser'

module PusherPlatform
  TOKEN_EXPIRY = 24*60*60

  class Authenticator

    def initialize(instance_id, key_id, key_secret)
      @instance_id = instance_id
      @key_id = key_id
      @key_secret = key_secret
      # see https://github.com/rack/rack/blob/5559676e7b5a3107d39552285ce8b714b672bde6/lib/rack/utils.rb#L27
      @query_parser = QueryParser.make_default(65536, 100)
    end

    def authenticate(auth_payload, options)
      grant_type = auth_payload['grant_type'] || auth_payload[:grant_type]

      unless grant_type == "client_credentials"
        return AuthenticationResponse.new({
          status: 422,
          body: {
            error: 'token_provider/invalid_grant_type',
            error_description: "The grant_type provided, #{grant_type}, is unsupported"
          }
        })
      end

      authenticate_using_client_credentials(options)
    end

    def authenticate_with_request(request, options)
      auth_data = @query_parser.parse_nested_query request.body.read
      authenticate(auth_data, options)
    end

    def authenticate_with_refresh_token(auth_payload, options)
      authenticate_based_on_grant_type(auth_payload, options)
    end

    def authenticate_with_refresh_token_and_request(request, options)
      auth_data = @query_parser.parse_nested_query request.body.read
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
      claims.merge!(options[:service_claims]) if options[:service_claims]

      {
        token: JWT.encode(claims, @key_secret, 'HS256'),
        expires_in: TOKEN_EXPIRY
      }
    end

    private

    def authenticate_based_on_grant_type(auth_data, options)
      grant_type = auth_data['grant_type'] || auth_data[:grant_type]

      if grant_type == "client_credentials"
        return authenticate_using_client_credentials(options, true)
      elsif grant_type == "refresh_token"
        refresh_token = auth_data['refresh_token'] || auth_data[:refresh_token]
        return authenticate_using_refresh_token(refresh_token, options)
      else
        return AuthenticationResponse.new({
          status: 422,
          body: ErrorBody.new({
            error: 'token_provider/invalid_grant_type',
            error_description: "The grant_type provided, #{grant_type}, is unsupported"
          })
        })
      end
    end

    def authenticate_using_client_credentials(options, with_refresh_token = false)
      access_token = generate_access_token(options)[:token]
      token_payload = {
        access_token: access_token,
        token_type: "bearer",
        expires_in: TOKEN_EXPIRY
      }

      token_payload[:refresh_token] = generate_refresh_token(options)[:token] if with_refresh_token

      return AuthenticationResponse.new({
        status: 200,
        body: token_payload
      })
    end

    def authenticate_using_refresh_token(refresh_token, options)
      old_refresh_token = begin
        JWT.decode(refresh_token, @key_secret, true, {
          algorithm: 'HS256',
          iss: "api_keys/#{@key_id}",
          verify_iss: true,
        }).first
      rescue => e
        error_description = if e.is_a?(JWT::InvalidIssuerError)
          "Refresh token issuer is invalid"
        elsif e.is_a?(JWT::ImmatureSignature)
          "Refresh token is not valid yet"
        elsif e.is_a?(JWT::ExpiredSignature)
          "Refresh token has expired"
        else
          "Refresh token is invalid"
        end

        return AuthenticationResponse.new({
          status: 401,
          body: ErrorBody.new({
            error: "token_provider/invalid_refresh_token",
            error_description: error_description
          })
        })
      end

      if old_refresh_token["refresh"] != true
        return AuthenticationResponse.new({
          status: 401,
          body: ErrorBody.new({
            error: "token_provider/invalid_refresh_token",
            error_description: "Refresh token does not have a refresh claim"
          })
        })
      end

      if options[:user_id] != old_refresh_token["sub"]
        return AuthenticationResponse.new({
          status: 401,
          body: ErrorBody.new({
            error: "token_provider/invalid_user_id_in_refresh_token",
            error_description: "Refresh token has an invalid user id"
          })
        })
      end

      return AuthenticationResponse.new({
        status: 200,
        body: new_token_pair(options)
      })
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
