require 'sinatra'
require 'json'
require 'cgi'
require_relative '../lib/pusher'

authorizer = Pusher::Authorizer.new("myAppId", "Issuer1:S3cr3t")

post '/pusherplatform/authorize' do
    form_data = Rack::Utils.parse_nested_query request.body.read

    grant_type = form_data["grant_type"]
    if grant_type == "client_credentials"
        credentials = form_data["credentials"]
        puts credentials
        payload = authorizer.authorize_credentials(credentials)
        
        content_type :json
        payload.to_json

    elsif grant_type == "refresh_token"
        token = form_data["refresh_token"]
        payload = authorizer.authorize_token(token)

        content_type :json
        payload.to_json

    else #fuckup
        400
    end
end