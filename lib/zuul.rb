require 'zuul/exceptions'
require 'zuul/configuration'

module Zuul
  mattr_reader :configuration
  @@configuration = Zuul::Configuration.new

  def self.configure(&block)
    @@configuration.configure &block
  end
  
  def self.should_whitelist?
    active_record3? or active_record4? && protected_attribtues?
  end
  
  def self.active_record3?
    ::ActiveRecord::VERSION::MAJOR == 3
  end
  
  def self.active_record4?
    ::ActiveRecord::VERSION::MAJOR == 4
  end

  def self.protected_attribtues?
    defined? ::ProtectedAttributes
  end
end

require 'zuul/context'
require 'zuul/active_record'
require 'zuul/action_controller'

require 'zuul/railtie' if defined?(Rails)
