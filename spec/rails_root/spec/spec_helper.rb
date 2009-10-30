ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'spec'
require 'spec/rails'

Spec::Runner.configure do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
  config.global_fixtures = :all
  config.mock_with :mocha
end

ActiveRecord::Base.establish_connection(
  :adapter  => 'sqlite3',
  :database => File.join(File.dirname(__FILE__), '../db/test.sqlite3')
)

class CreateSchema < ActiveRecord::Migration
  def self.up
    create_table :users, :force => true do |t|
      t.string  :first_name
      t.string  :last_name
      t.string  :email
      t.string  :username
      t.string  :role
    end
  end
end

CreateSchema.suppress_messages { CreateSchema.migrate(:up) }

class ActiveSupport::TestCase
end
