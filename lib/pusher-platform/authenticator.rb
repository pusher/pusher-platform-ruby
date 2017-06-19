require 'jwt'
require 'rack'

module Pusher
  TOKEN_LEEWAY = 30
  TOKEN_EXPIRY = 24*60*60

  class Authenticator
    def initialize(app_id, app_key_id, app_key_secret)
      @app_id = app_id
      @app_key_id = app_key_id
      @app_key_secret = app_id
    end

    # Takes a Rack request to the authorization endpoint and and handles it
    # either returning a new access/refresh token pair, or an error.
    #
    # @param request [Rack::Request] the request to authenticate
    # @return the response object
    def authenticate(request, options)
      form_data = Rack::Utils.parse_nested_query request.body.read
      grant_type = form_data['grant_type']

      if grant_type == "client_credentials"
        return authenticate_with_client_credentials(options)
      elsif grant_type == "refresh_token"
        old_refresh_jwt = form_data['refresh_token']
        return authenticate_with_refresh_token(old_refresh_jwt, options)
      else
        return response(401, {
          error: "unsupported_grant_type"
        })
      end
    end

    private

    def authenticate_with_client_credentials(options)
      return respond_with_new_token_pair(options)
    end

    def authenticate_with_refresh_token(old_refresh_jwt, options)
      old_refresh_token = begin
        JWT.decode(old_refresh_jwt, @app_key_secret, true, {
          iss: "api_keys/#{@app_key_id}",
          verify_iss: true,
          leeway: 30,
        }).first
      rescue => e
        error_description = if e.is_a?(JWT::InvalidIssuerError)
          "refresh token issuer is invalid"
        elsif e.is_a?(JWT::ImmatureSignature)
          "refresh token is not valid yet"
        elsif e.is_a?(JWT::ExpiredSignature)
          "refresh tokan has expired"
        else
          "refresh token is invalid"
        end

        return response(401, {
          error: "invalid_grant",
          error_description: error_description,
          # TODO error_uri
        })
      end

      if old_refresh_token["refresh"] != true
        return response(401, {
          error: "invalid_grant",
          error_description: "refresh token does not have a refresh claim",
          # TODO error_uri
        })
      end

      if options[:user_id] != old_refresh_token["sub"]
        return response(401, {
          error: "invalid_grant",
          error_description: "refresh token has an invalid user id",
          # TODO error_uri
        })
      end

      return respond_with_new_token_pair(options)
    end

    # Creates a payload dictionary made out of access and refresh token pair and TTL for the access token.
    #
    # @param user_id [String] optional id of the user, ignore for anonymous users
    # @return [Hash] Payload as a hash
    def respond_with_new_token_pair(options)
      access_token = generate_access_token(options)
      refresh_token = generate_refresh_token(options)
      return response(200, {
        access_token: access_token,
        token_type: "bearer",
        expires_in: TOKEN_EXPIRY,
        refresh_token: refresh_token,
      })
    end

    def generate_access_token(options)
      now = Time.now.utc.to_i

      claims = {
        app: @app_id,
        iss: "api_keys/#{@app_key_id}",
        iat: now - TOKEN_LEEWAY,
        exp: now + TOKEN_EXPIRY + TOKEN_LEEWAY,
        sub: options[:user_id],
      }

      JWT.encode(claims, @app_key_secret, "HS256")
    end

    def generate_refresh_token(options)
      now = Time.now.utc.to_i

      claims = {
        app: @app_id,
        iss: "api_keys/#{@app_key_id}",
        iat: now - TOKEN_LEEWAY,
        refresh: true,
        sub: options[:user_id],
      }

      JWT.encode(claims, @app_key_secret, "HS256")
    end

    def response(status, body)
      return {
        status: status,
        json: body,
      }
    end
  end
end
