require 'active_support'
require 'active_record'
require 'action_controller'
require 'allowables'
require 'rspec'

Dir[File.join(File.dirname(__FILE__), '..', "spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.before(:suite) do
    ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"
    capture_stdout { load "spec/db/schema.rb" }
  end

  config.around(:each) do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end
