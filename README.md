# pusher-platform-ruby

Pusher Platform SDK for Ruby.

## Installation

Add `pusher-platform` to your Gemfile:

```
gem 'pusher-platform', '~> 0.2.0'
```

## Usage

In order to access Pusher Platform, first instantiate an App object:

```ruby
require 'pusher-platform'

pusher = Pusher::App.new(
  cluster: "",
  app_id: "",
  app_key: "",
)
```

### Authentication (Rails + Devise)

App objects provide an `authenticate` method, which can be used in Rails
controllers to build authentication endpoints. Authentication endpoints issue
access tokens used by Pusher Platform clients to access the API.

Make sure you authenticate the user before issuing access tokens, e.g. by using
the `authenticate_user!` Devise filter.

```ruby
class AuthController < ActionController::Base
  before_action :authenticate_user!

  def auth
    render pusher.authenticate(request, {
      user_id: current_user.id,
    })
  end
end
```

### Request API

App objects provide a low-level request API, which can be used to contact
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
rescue Pusher::ErrorResponse => e
  p e.status
  p e.headers
  p e.description
rescue
  p e
end
```
