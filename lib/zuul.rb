require 'protected_attributes'
require 'zuul/exceptions'
require 'zuul/configuration'

module Zuul
  mattr_reader :configuration
  @@configuration = Zuul::Configuration.new

  def self.configure(&block)
    @@configuration.configure &block
  end
  
  def self.should_whitelist?
    rails3? or rails4? && protected_attribtues?
  end
  
  def self.rails3?
    3 == Rails::VERSION::MAJOR
  end
  
  def self.rails4?
    4== Rails::VERSION::MAJOR
  end

  def self.protected_attribtues?
    defined? ::ProtectedAttributes
  end
end

require 'zuul/context'
require 'zuul/active_record'
require 'zuul/action_controller'

require 'zuul/railtie' if defined?(Rails)
