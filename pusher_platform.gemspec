Gem::Specification.new do |s|
  s.name        = 'pusher-platform'
  s.version     = '0.11.0'
  s.licenses    = ['MIT']
  s.summary     = "Pusher Platform Ruby SDK"
  s.authors     = ["Pusher"]
  s.email       = 'support@pusher.com'
  s.files       = `git ls-files -- lib/*`.split("\n")

  s.add_runtime_dependency 'excon', '~> 0.62.0'
  s.add_runtime_dependency 'jwt', '~> 2.1'
end
