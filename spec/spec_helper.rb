# $LOAD_PATH.unshift(File.dirname(__FILE__))
# $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
# require 'spec'
# require 'spec/rails'
require 'activerecord'
require 'zuul'

ActiveRecord::Base.establish_connection(
  :adapter  => 'sqlite3',
  :database => File.join(File.dirname(__FILE__), 'test.db')
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

class User < ActiveRecord::Base
  validates_presence_of :first_name, :last_name, :email
  valid_roles :guest, :member, :admin
end
