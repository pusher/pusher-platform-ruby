require_relative '../lib/pusher-platform'

# Get these from the Dashbaord
instance = PusherPlatform::Instance.new(
  locator: 'your:instance:locator',
  key: 'your:key',
  service_name: 'feeds',
  service_version: 'v1'
)

server_token_claims = {
  service_claims: {
    feeds: {
      permission: {
        path: '*',
        action: '*'
      }
    }
  }
}

jwt = instance.generate_access_token(server_token_claims)[:token]

puts instance.request({
  jwt: jwt,
  method: 'POST',
  path: 'feeds/test/items',
  body: { items: [ "test item" ] }
}).inspect
