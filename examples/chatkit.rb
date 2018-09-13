require_relative '../lib/pusher-platform'

# Get these from the Dashbaord
instance = PusherPlatform::Instance.new(
  locator: 'your:instance:locator',
  key: 'your:key',
  service_name: 'chatkit',
  service_version: 'v1'
)

# We need a su token to create a Chatkit user
jwt = instance.generate_access_token({ su: true })[:token]

# This will create a Chatkit user
puts instance.request({
  jwt: jwt,
  method: 'POST',
  path: '/users',
  body: { id: 'ham', name: 'Ham Chapman' }
}).inspect
