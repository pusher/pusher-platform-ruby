require 'sinatra'
require 'json'
require 'cgi'
require_relative '../lib/pusher-platform'

# Get these from the Dashbaord
instance = PusherPlatform::Instance.new(
  locator: 'v1:api-ceres:some-instance-id',
  key: 'key-id:key-secret',
  service_name: 'chatkit',
  service_version: 'v1'
)

post '/' do
  auth_payload = instance.authenticate_with_request(request, { user_id: 'ham' })
  [auth_payload.status, auth_payload.body.to_json]
end

post '/refresh' do
  auth_payload = instance.authenticate_with_refresh_token_and_request(request, { user_id: 'ham' })
  [auth_payload.status, auth_payload.body.to_json]
end
