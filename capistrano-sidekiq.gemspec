$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "capistrano/sidekiq/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "capistrano-sidekiq"
  s.version     = Capistrano::Sidekiq::VERSION
  s.authors     = ["Evgeniy"]
  s.email       = ["evgeniytka4enko@gmail.com"]
  s.homepage    = "https://github.com/evgeniytka4enko/capistrano-sidekiq"
  s.summary     = s.description
  s.description = "Sidekiq systemd integration for Capistrano"
  s.license     = "MIT"

  s.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  s.require_paths = ["lib"]

  s.add_dependency "capistrano"
  s.add_dependency "sidekiq", ">= 3.4"
  s.add_dependency "sshkit-sudo"
end
