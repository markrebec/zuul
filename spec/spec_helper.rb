ENV["RAILS_ENV"] ||= 'test'
require 'active_support'
require 'active_record'
require 'action_controller'
require 'allowables'
require 'rspec'
require 'database_cleaner'

Dir[File.join(File.dirname(__FILE__), '..', "spec/support/**/*.rb")].each { |f| require f }

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"
capture_stdout { load "spec/db/schema.rb" }

RSpec.configure do |config|
  #config.use_transactional_fixtures = false # Using DatabaseCleaner transactions instead

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
  
  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  #config.infer_base_class_for_anonymous_controllers = true
end
