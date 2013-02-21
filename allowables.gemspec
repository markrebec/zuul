$:.push File.expand_path("../lib", __FILE__)
require "allowables/version"

Gem::Specification.new do |s|
  s.name        = "allowables"
  s.version     = Allowables::VERSION
  s.date        = "2012-01-04"
  s.summary     = "Access Control for Rails."
  s.description = "Flexible and easy to use authorization system for Rails."
  s.authors     = ["Mark Rebec"]
  s.email       = ["mark@markrebec.com"]
  s.files       = Dir["lib/**/*"]
  s.test_files  = Dir["spec/**/*"]
  s.homepage    = "http://github.com/markrebec/allowables"

  s.add_dependency "rails"

  s.add_development_dependency "rspec"
  s.add_development_dependency "database_cleaner"
end
