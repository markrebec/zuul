$:.push File.expand_path("../lib", __FILE__)
require "allowables/version"

Gem::Specification.new do |s|
  s.name        = "allowables"
  s.version     = Allowables::VERSION
  s.date        = "2013-02-19"
  s.summary     = "Authorizaion for Activerecord and Access Control for ActionController."
  s.description = "Flexible and easy to use authorization system for ActiveRecord and ActionController."
  s.authors     = ["Mark Rebec"]
  s.email       = ["mark@markrebec.com"]
  s.files       = Dir["lib/**/*"]
  s.test_files  = Dir["spec/**/*"]
  s.homepage    = "http://github.com/markrebec/allowables"

  s.add_dependency "activesupport"
  s.add_dependency "activerecord"
  s.add_dependency "actionpack"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec"
end
