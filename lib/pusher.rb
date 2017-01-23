require 'jwt'
require 'rack'

ONE_DAY = 86400
TWO_WEEKS = 1209600

module Pusher
    class App    
        def initialize(app_id, api_key)
            @app_id = app_id

            split_key = api_key.split(":")
            @issuer_key = split_key[0]
            @secret_key = split_key[1]
        end

        # Takes a Rack request to the authorization endpoint and and handles it
        # either returning a new access/refresh token pair, or an error. 
        # 
        # @param request [Rack::Request] the request to authorize
        # @return the response object
        def authorize(request)
            form_data = Rack::Utils.parse_nested_query request.body.read

            grant_type = form_data["grant_type"]
            if grant_type == "client_credentials"
                credentials = form_data["credentials"]
                payload = authorize_credentials(credentials)
        
                response = Rack::Response.new(payload.to_json, 200, {"Content-type" => "application/json"})

            elsif grant_type == "refresh_token"
                token = form_data["refresh_token"]
                payload = authorize_token(token)

                response = Rack::Response.new(payload.to_json, 200, {"Content-type" => "application/json"})

            else #fuckup
                error = {:error => "invalid_request", :error_description => "Grant type should be either client_credentials or refresh_token"}
                response = Rack::Response.new(error.to_json, 400, {"Content-type" => "application/json"})
            end
            response
        end

        # Creates a payload dictionary made out of access and refresh token pair and TTL for the access token.
        #
        # @param user_id [String] optional id of the user, ignore for anonymous users
        # @return [Hash] Payload as a hash 
        def authorize_credentials(user_id = nil)
            time = Time.now.to_i  

            access_token = jwt_create(user_id, time + ONE_DAY)
            refresh_token = jwt_create(user_id, time + TWO_WEEKS)
        
            payload =  {
                :access_token => access_token,
                :token_type => "bearer",
                :expires_in => ONE_DAY,
                :refresh_token => refresh_token
            }
            payload
        end

        def jwt_create(user_id, exp)
            payload = {
                :exp => exp,
                :iss => @issuer_key,
                :app => @app_id
            }
            if(user_id)
                payload[:sub] = user_id    
            end
            
            JWT.encode payload, @secret_key, 'HS256'    
        end

        # Creates a payload of refresh and access tokens, from a refresh token.
        # 
        # @param refresh_token [String] a JWT refresh token
        def authorize_token(refresh_token)
            decoded_refresh_token = JWT.decode refresh_token, @secret_key, true, { :algorithm => 'HS256' }
            user_id = decoded_refresh_token[0]["sub"]
            authorize_credentials(user_id)
        end
    end        
end