Gem::Specification.new do |s|
  s.name        = 'pusher-platform'
  s.version     = '0.5.1'
  s.licenses    = ['MIT']
  s.summary     = "Pusher Platform Ruby SDK"
  s.authors     = ["Pusher"]
  s.email       = 'support@pusher.com'
  s.files       = `git ls-files -- lib/*`.split("\n")

  s.add_runtime_dependency 'excon', '~> 0.54.0'
  s.add_runtime_dependency 'jwt', '~> 1.5', '>= 1.5.6'
  s.add_runtime_dependency 'rack', '>= 1.0'
end
