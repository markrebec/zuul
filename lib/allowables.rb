require 'allowables/exceptions'
require 'allowables/configuration'
require 'allowables/context'
require 'allowables/active_record'
require 'allowables/action_controller'

module Allowables
  mattr_reader :configuration
  @@configuration = Allowables::Configuration.new

  def self.configure(&block)
    @@configuration.configure &block
  end
end
