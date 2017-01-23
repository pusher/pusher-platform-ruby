require_relative 'Pusher'

authorizer = Pusher::Authorizer.new("app_id", "ISSUER1:S3CR3T")

payload = authorizer.authorize_credentials("12313")
puts payload

sleep(1)
puts "using refresh token: #{payload[:refresh_token]}" 
refreshed = authorizer.authorize_token(payload[:refresh_token])
puts refreshed
        