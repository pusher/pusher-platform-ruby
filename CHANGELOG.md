# Changelog

## Unreleased

## [0.8.0] 2018-04-20

### Additions

- `authenticate_with_refresh_token` has been added if you want to support the `refresh_token` grant type and return refresh tokens as part of the authentication process
- `authenticate_with_refresh_token_and_request` has been added if you want to support the `refresh_token` grant type and return refresh tokens as part of the authentication process, as well as providing the request object when authenticating

### Changes

- `authenticate` no longer returns a `refresh_token` and no longer accepts the `refresh_token` grant type
- Calls to `authenticate` and `authenticate_with_refresh_token` always return an `AuthenticationResponse` that looks like this (in JSON form):

```ruby
{
  status: 200,
  headers: { "Some-Header" => "some value" },
  body: {
    access_token: "an_access_token",
    token_type: "bearer",
    expires_in: 86400
  }
}
```

where:

* `status` is the suggested HTTP response status code,
* `headers` are the suggested response `headers`,
* `body` holds either the token payload or an appropriate error payload.

Here is an example of the expected usage (using Sinatra), simplified for brevity:

```ruby
post '/' do
  auth_payload = instance.authenticate_with_request(request, { user_id: 'USER_ID' })
  [auth_payload.status, auth_payload.body.to_json]
end
```

## [0.7.0] 2018-04-12

### Changes

- Rename `authenticate` to `authenticate_with_request`
- `authenticate` (now `authenticate_with_request`) no longer returns a status code. It will either return a `Hash` containing the required authentication payload or an error with information about the reason for authentication failure
- Add some examples

### Added

- Examples for `authenticate` and `authenticate_with_request`

### Fixed

- Changed module name from `Pusher` to `PusherPlatform` (fixes #15)
- Fixes some `require`s

## [0.6.0] 2018-01-26

### Changes

- `app` claim in JWTs changed to `instance`

_.. prehistory_
