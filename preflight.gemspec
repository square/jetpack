# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = "preflight"
  s.version     = "0.0.1"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Steve Conover"]
  s.email       = ["steve@squareup.com"]
  s.homepage    = "https://git.squareup.com/square/preflight"
  s.summary     = %q{Preflight prepares your jRuby project for jvm deployment.}

  s.add_development_dependency "bundler"
  
  s.files         = `git ls-files`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.require_paths = ["bin"]  #Need at least one require path...
  # s.executables        = %w(bundle)
end
