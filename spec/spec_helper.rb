require 'active_support'
require 'active_record'
require 'action_controller'
require 'zuul'
require 'rspec'

I18n.enforce_available_locales = false

Dir[File.join(File.dirname(__FILE__), '..', "spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.before(:suite) do
    ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"
    capture_stdout { load "db/schema.rb" }
  end

  config.before(:each) do
    load 'support/models.rb'
  end

  config.around(:each) do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end

# TODO research why I need to patch these to work with default behavior?
class FalseClass
  def false?
    true
  end

  def true?
    false
  end
end

class TrueClass
  def false?
    false
  end

  def true?
    true
  end
end
