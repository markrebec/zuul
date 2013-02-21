require 'active_support'
require 'active_record'
require 'action_controller'
require 'allowables'
require 'rspec'
require 'database_cleaner'

Dir[File.join(File.dirname(__FILE__), '..', "spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.before(:suite) do
    ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"
    capture_stdout { load "spec/db/schema.rb" }
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
