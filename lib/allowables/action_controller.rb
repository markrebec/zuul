require 'allowables/action_controller/dsl'

module Allowables
  module ActionController
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end

    class ForTargetHelper
      def for_target(&block)
        return self if @dsl.nil?
        if match?
          @controller.instance_eval do
            yield
          end if block_given?
        end
        self
      end

      def else(&block)
        return self if @dsl.nil?
        if !match?
          @controller.instance_eval do
            yield
          end if block_given?
        end
        self
      end

      def else_for(target, context=nil, force_context=nil, &block)
        return self.class.new(@controller, target, context, force_context, &block)
      end

      protected

      def initialize(controller, target, context=nil, force_context=nil, &block)
        @controller = controller
        @dsl = @controller.acl_dsl
        @target = target
        @context = context
        @force_context = force_context
        for_target &block
      end
    end

    class ForRoleHelper < ForTargetHelper
      def match?
        (@dsl.subject.nil? && @target == @dsl.logged_out) || (!@dsl.subject.nil? && (@target == @dsl.logged_in || @dsl.subject.has_role?(@target, @context, @force_context)))
      end
    end

    class ForRoleOrHigherHelper < ForTargetHelper
      def match?
        (@dsl.subject.nil? && @target == @dsl.logged_out) || (!@dsl.subject.nil? && (@target == @dsl.logged_in || @dsl.subject.has_role_or_higher?(@target, @context, @force_context)))
      end
    end
    
    class ForPermissionHelper < ForTargetHelper
      def match?
        @dsl.subject.has_permission?(@target, @context, @force_context)
      end
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
        return ForRoleHelper.new(self, role, context, force_context, &block)
      end
      
      def for_role_or_higher(role, context=nil, force_context=nil, &block)
        return ForRoleOrHigherHelper.new(self, role, context, force_context, &block)
      end
      
      def for_permission(permission, context=nil, force_context=nil, &block)
        return ForPermissionHelper.new(self, permission, context, force_context, &block)
      end
      
      def except_for_role(role, context=nil, force_context=nil, &block)
        return ForRoleHelper.new(self, role, context, force_context).else(&block)
      end
      
      def except_for_role_or_higher(role, context=nil, force_context=nil, &block)
        return ForRoleOrHigherHelper.new(self, role, context, force_context).else(&block)
      end
      
      def except_for_permission(permission, context=nil, force_context=nil, &block)
        return ForPermissionHelper.new(self, permission, context, force_context).else(&block)
      end
    end
    
    module ClassMethods
      def self.extended(base)
        base.send :cattr_accessor, :acl_filters
        base.send :cattr_accessor, :used_acl_filters
        base.send :class_variable_set, :@@acl_filters, []
        base.send :class_variable_set, :@@used_acl_filters, []
        base.send :attr_accessor, :acl_dsl
      end

      def access_control(*args, &block)
        opts, filter_args = parse_access_control_args(*args)
        
        acl_filters << append_before_filter(filter_args) do |controller|
          self.class.used_acl_filters << self.class.acl_filters.slice!(0)
          
          controller.acl_dsl ||= DSL::Base.new(controller)
          controller.acl_dsl.configure opts
          controller.acl_dsl.execute &block

          if self.class.acl_filters.length == 0
            self.class.acl_filters = self.class.used_acl_filters
            self.class.used_acl_filters = []
            raise Exceptions::AccessDenied if !controller.acl_dsl.authorized? && controller.acl_dsl.mode != :quiet
          end
        end
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
        filter_args = args.select { |k,v| [:except, :only].include?(k) }
        [:except, :only].each { |k| args.delete(k) }
        return [args, filter_args]
      end
    end
  end
end

ActionController::Base.send :include, Allowables::ActionController
