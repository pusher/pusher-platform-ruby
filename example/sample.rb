require 'sinatra'
require 'json'
require 'cgi'
require_relative '../lib/pusher'

# Get these from the Dashbaord
app = Pusher::App.new("myAppId", "Issuer1:S3cr3t")

post '/pusherplatform/authorize' do
    app.authorize (request)
end