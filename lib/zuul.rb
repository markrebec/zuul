require 'zuul/exceptions'
require 'zuul/configuration'

module Zuul
  mattr_reader :configuration
  @@configuration = Zuul::Configuration.new

  def self.configure(&block)
    @@configuration.configure &block
  end
end

require 'zuul/context'
require 'zuul/active_record'
require 'zuul/action_controller'
