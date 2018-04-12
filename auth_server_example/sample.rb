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
  instance.authenticate_with_request(request, { user_id: 'ham' }).to_json
end
