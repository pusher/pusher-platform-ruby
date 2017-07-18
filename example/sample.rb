require 'sinatra'
require 'json'
require 'cgi'
require_relative '../lib/pusher'

# Get these from the Dashbaord
instance = Pusher::Instance.new(
  instance: 'v1:api-ceres:some-instance-id',
  key: 'key-id:key-secret',
  service_name: 'chatkit',
  service_version: 'v1'
)

post '/pusherplatform/authorize' do
  instance.authorize (request)
end
