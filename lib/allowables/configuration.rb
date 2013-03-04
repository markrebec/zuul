module Allowables
  class Configuration
    PRIMARY_AUTHORIZATION_CLASSES = {
      :subject_class => :user,
      :role_class => :role,
      :permission_class => :permission
    }
    AUTHORIZATION_JOIN_CLASSES = {
      :role_subject_class => :role_user,
      :permission_role_class => :permission_role,
      :permission_subject_class => :permission_user
    }
    DEFAULT_AUTHORIZATION_CLASSES = PRIMARY_AUTHORIZATION_CLASSES.merge(AUTHORIZATION_JOIN_CLASSES)
    
    DEFAULT_CONFIGURATION_OPTIONS = {
      :acl_default => :deny,
      :subject_method => :current_user,
      :with_permissions => true
    }

    attr_accessor *DEFAULT_AUTHORIZATION_CLASSES.keys
    attr_accessor *DEFAULT_CONFIGURATION_OPTIONS.keys

    def configure(&block)
      self.instance_eval(&block) if block_given?
    end

    protected

    def initialize
      [DEFAULT_AUTHORIZATION_CLASSES, DEFAULT_CONFIGURATION_OPTIONS].each do |opts|
        opts.each do |key,val|
          instance_variable_set "@#{key.to_s}", val
        end
      end
      super
    end
  end
end
