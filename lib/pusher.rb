require 'jwt'

ONE_DAY = 86400
TWO_WEEKS = 1209600

module Pusher
    class Authorizer
        attr_accessor :app_id, :issuer_key, :secret_key

        def initialize(app_id, api_key)
            @app_id = app_id

            split_key = api_key.split(":")
            @issuer_key = split_key[0]
            @secret_key = split_key[1]
        end

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

        def authorize_token(refresh_token)
            decoded_refresh_token = JWT.decode refresh_token, @secret_key, true, { :algorithm => 'HS256' }
            user_id = decoded_refresh_token[0]["sub"]
            authorize_credentials(user_id)
        end
    end        
end