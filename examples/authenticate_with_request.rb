require_relative '../lib/pusher-platform'

# Get these from the Dashbaord
instance = PusherPlatform::Instance.new(
  locator: 'v1:api-ceres:some-instance-id',
  key: 'key-id:key-secret',
  service_name: 'chatkit',
  service_version: 'v1'
)

# FakeRequest and FakeRequestBody are used here to mimic Rack::Request

class FakeRequest
  def initialize
  end

  def body
    FakeRequestBody.new
  end
end

class FakeRequestBody
  def initialize
  end

  def read
    'grant_type=refresh_token&refresh_token=AyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpbnN0YW5jZSI6InNvbWUtaW5zdGFuY2UtaWQiLCJpc3MiOiJhcGlfa2V5cy9rZXktaWQiLCJpYXQiOjE1MjMyOTEyMzEsInJlZnJlc2giOnRydWUsInN1YiI6ImhhbSJ9.BvvcD4gIBLK43uNrykSLZbUP5LNqG1UPisv2x_T_vs8'
    # 'grant_type=client_credentials'
  end
end

puts instance.authenticate_with_request(FakeRequest.new, { user_id: 'ham' })
