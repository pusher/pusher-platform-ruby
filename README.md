# pusher-platform-ruby

Pusher Platform SDK for Ruby.

## Installation

Add `pusher-platform` to your Gemfile:

```
gem 'pusher-platform', '~> 0.6.0'
```

## Usage

In order to access Pusher Platform, first instantiate an Instance object:

```ruby
require 'pusher-platform'

pusher = PusherPlatform::Instance.new(
  locator: 'your:instance:locator',
  key: 'key-id:key-secret',
  service_name: 'chatkit',
  service_version: 'v1'
)
```

### Authentication (Rails + Devise)

Instance objects provide an `authenticate` method, which can be used in Rails
controllers to build authentication endpoints. Authentication endpoints issue
access tokens used by Pusher Platform clients to access the API.

Make sure you authenticate the user before issuing access tokens, e.g. by using
the `authenticate_user!` Devise filter.

```ruby
class AuthController < ActionController::Base
  before_action :authenticate_user!

  def auth
    render json: pusher.authenticate_with_request(
      request,
      { user_id: current_user.id }
    )
  end
end
```

### Request API

Instance objects provide a low-level request API, which can be used to contact
Pusher Platform.

```ruby
begin
  response = pusher.request(
    method: "POST",
    path: "feeds/playground",
    headers: {
      "Content-Type": "application/json",
    },
    body: { items: ["test"] }.to_json
  )
  p response.status
  p response.headers
  p response.body
rescue PusherPlatform::ErrorResponse => e
  p e.to_s
rescue
  p e
end
```
