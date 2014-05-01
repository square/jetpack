# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = "jetpack"
  s.version     = "0.1.5"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Steve Conover", "Xavier Shay", "Taylor Phillips", "Chris Heisterkamp"]
  s.email       = ["steve@squareup.com", "xavier@squareup.com", "taylor@squareup.com", "cheister@squareup.com"]
  s.homepage    = "https://github.com/square/jetpack"
  s.summary     = %q{Jetpack prepares your jRuby project for jvm deployment.}

  s.add_development_dependency "bundler"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec", "~> 2.14"

  s.files         = `git ls-files`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.require_paths = ["lib"]
end
