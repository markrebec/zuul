require 'zuul'
class User < ActiveRecord::Base
  include Zuul::ValidRoles

  validates_presence_of :first_name, :last_name, :email

  valid_roles :guest, :member, :admin
end
