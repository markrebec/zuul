require 'allowables/action_controller/dsl'

module Allowables
  module ActionController
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def self.extended(base)
        base.send :attr_accessor, :authorization_dsl
      end

      def access_control(*args, &block)
        before_filter(*args) do |controller|
          controller.authorization_dsl ||= DSL::Base.new(controller)
          puts "----------------------------"
          puts "START EXECUTING ACCESS CONTROL BLOCK"
          dsl.instance_eval(&block) if block_given?
          puts "DONE EXECUTING ACCESS CONTROL BLOCK"
          puts "----------------------------"
          puts "ACCESS CONTROL RESULTS"
          puts dsl.results.to_yaml
          puts "----------------------------"
        end
      end

      def allow_roles(roles, *args, &block)
      end
      alias_method :allow_role, :allow_roles

      def allow_permissions(permissions, *args, &block)
      end
      alias_method :allow_permission, :allow_permissions

      def deny_roles(roles, *args, &block)
      end
      alias_method :deny_role, :deny_roles

      def deny_permissions(permissions, *args, &block)
      end
      alias_method :deny_permission, :deny_permissions
    end

  end
end

ActionController::Base.send :include, Allowables::ActionController
