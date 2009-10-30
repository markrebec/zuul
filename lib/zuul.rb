require 'zuul/valid_roles'
require 'zuul/restrict_access'

# ActiveRecord::Base.send(:include, Zuul::ValidRoles::ClassMethods)

Class.class_eval do
  include Zuul::ValidRoles::ClassMethods
end
