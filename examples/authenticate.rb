require_relative '../lib/pusher-platform'

# Get these from the Dashbaord
instance = PusherPlatform::Instance.new(
  locator: 'v1:us1:some-instance-id',
  key: 'key-id:key-secret',
  service_name: 'chatkit',
  service_version: 'v1',
  sdk_info: PusherPlatform::SDKInfo.new(
    product_name: 'chatkit',
    version: '0.0.0'
  )
)

puts instance.authenticate({ grant_type: 'client_credentials' }, { user_id: 'ham' }).to_json

# OR
# puts instance.authenticate_with_refresh_token({ grant_type: 'client_credentials' }, { user_id: 'ham' })

# OR
# puts instance.authenticate_with_refresh_token({ grant_type: 'refresh_token', refresh_token: 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpbnN0YW5jZSI6InNvbWUtaW5zdGFuY2UtaWQiLCJpc3MiOiJhcGlfa2V5cy9rZXktaWQiLCJpYXQiOjE1MjMyOTEyMzEsInJlZnJlc2giOnRydWUsInN1YiI6ImhhbSJ9.BvvcD4gIBLK43uNrykSLZbUP5LNqG1UPisv2x_T_vs8' }, { user_id: 'ham' })
