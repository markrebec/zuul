require 'zuul/action_controller/dsl'
require 'zuul/action_controller/evaluators'

module Zuul
  module ActionController
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def self.included(base)
        base.send :helper_method, :authorized?
        base.send :helper_method, :for_role
        base.send :helper_method, :for_role_or_higher
        base.send :helper_method, :for_permission
        base.send :helper_method, :except_for_role
        base.send :helper_method, :except_for_role_or_higher
        base.send :helper_method, :except_for_permission
      end

      def authorized?
        return true if @acl_dsl.nil?
        @acl_dsl.authorized?
      end

      def for_role(role, context=nil, force_context=nil, &block)
        return Evaluators::ForRole.new(self, role, context, force_context, &block)
      end
      
      def for_role_or_higher(role, context=nil, force_context=nil, &block)
        return Evaluators::ForRoleOrHigher.new(self, role, context, force_context, &block)
      end
      
      def for_permission(permission, context=nil, force_context=nil, &block)
        return Evaluators::ForPermission.new(self, permission, context, force_context, &block)
      end
      
      def except_for_role(role, context=nil, force_context=nil, &block)
        return Evaluators::ForRole.new(self, role, context, force_context).else(&block)
      end
      
      def except_for_role_or_higher(role, context=nil, force_context=nil, &block)
        return Evaluators::ForRoleOrHigher.new(self, role, context, force_context).else(&block)
      end
      
      def except_for_permission(permission, context=nil, force_context=nil, &block)
        return Evaluators::ForPermission.new(self, permission, context, force_context).else(&block)
      end
    end
    
    module ClassMethods
      def self.extended(base)
        base.send :cattr_accessor, :used_acl_filters
        base.send :class_variable_set, :@@used_acl_filters, 0
        base.send :attr_accessor, :acl_dsl
      end

      def access_control(*args, &block)
        opts, filter_args = parse_access_control_args(*args)
        
        callback_method = "_zuul_callback_before_#{acl_filters.length+1}".to_sym
        define_method callback_method do |controller|
          controller.acl_dsl ||= DSL::Base.new(controller)
          controller.acl_dsl.configure opts
          controller.acl_dsl.execute &block
          self.class.used_acl_filters += 1

          if self.class.used_acl_filters == self.class.acl_filters.length
            self.class.used_acl_filters = 0
            raise Exceptions::AccessDenied if !controller.acl_dsl.authorized? && controller.acl_dsl.mode != :quiet
          end
        end
        append_before_filter "#{callback_method.to_s}(self)".to_sym, filter_args
      end

      def acl_filters
        _process_action_callbacks.select { |f| f.kind == :before && f.filter.match(/\A_zuul_callback_before_.*/) }
      end

      # TODO maybe implement these to be used as simple wrappers for access_control
      #def allow_roles(roles, *args, &block)
      #end
      #alias_method :allow_role, :allow_roles

      #def allow_permissions(permissions, *args, &block)
      #end
      #alias_method :allow_permission, :allow_permissions

      #def deny_roles(roles, *args, &block)
      #end
      #alias_method :deny_role, :deny_roles

      #def deny_permissions(permissions, *args, &block)
      #end
      #alias_method :deny_permission, :deny_permissions

      def parse_access_control_args(*args)
        args = args[0] if args.is_a?(Array)
        args = {} if args.nil?
        filter_args = args.select { |k,v| filter_keys.include?(k) }
        args.reject! { |k| filter_keys.include?(k) }
        return [args, filter_args]
      end

      def filter_keys
        [:except, :only]
      end
    end
  end
end

ActionController::Base.send :include, Zuul::ActionController
