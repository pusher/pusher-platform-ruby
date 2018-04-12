# Changelog

## Unreleased

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
