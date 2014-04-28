require 'zuul/active_record/scope'
require 'zuul/active_record/role'
require 'zuul/active_record/permission'
require 'zuul/active_record/context'
require 'zuul/active_record/subject'
require 'zuul/active_record/role_subject'
require 'zuul/active_record/permission_role'
require 'zuul/active_record/permission_subject'

module Zuul
  module ActiveRecord
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end

    module ClassMethods
      def self.extended(base)
      end

      # Includes auth methods into the model and configures auth options and scopes
      #
      # The args parameter is an optional hash of configuration options.
      def acts_as_authorization_model(args={}, &block)
        #zuul_modules << :authorization_methods
        include AuthorizationMethods unless ancestors.include?(AuthorizationMethods)
        auth_config = Zuul.configuration.clone.configure(args, &block)
        @auth_scopes ||= {}
        @auth_scopes[auth_config.scope] = Scope.new(auth_config)
        @auth_scopes[:default] ||= @auth_scopes[auth_config.scope]
        @auth_scopes[auth_config.scope]
      end

      # Configure the model to act as a zuul authorization role
      #
      # The args parameter is an optional hash of configuration options.
      def acts_as_authorization_role(args={}, &block)
        scope = acts_as_authorization_model(args.merge({:role_class => self.name}), &block)
        prepare_join_classes scope.name
        zuul_modules << :role
        include Role 
      end

      # Configure the model to act as a zuul authorization permission
      #
      # The args parameter is an optional hash of configuration options.
      def acts_as_authorization_permission(args={}, &block)
        scope = acts_as_authorization_model(args.merge({:permission_class => self.name}), &block)
        prepare_join_classes scope.name
        zuul_modules << :permission
        include Permission
      end

      # Configure the model to act as a zuul authorization subject
      #
      # The args parameter is an optional hash of configuration options.
      def acts_as_authorization_subject(args={}, &block)
        scope = acts_as_authorization_model(args.merge({:subject_class => self.name}), &block)
        prepare_join_classes scope.name
        zuul_modules << :subject
        include Subject
      end

      # Configure the model to act as a zuul authorization context (or resource)
      #
      # The args parameter is an optional hash of configuration options.
      def acts_as_authorization_context(args={}, &block)
        scope = acts_as_authorization_model(args, &block)
        prepare_join_classes scope.name
        zuul_modules << :context
        include Context
      end

      # Configure the model to act as a zuul joining model for roles and subjects
      #
      # The args parameter is an optional hash of configuration options.
      def acts_as_authorization_permission_role(args={}, &block)
        scope = acts_as_authorization_model(args.merge({:permission_role_class => self.name}), &block)
        zuul_modules << :permission_role
        include PermissionRole
      end

      # Configure the model to act as a zuul joining model for roles and subjects
      #
      # The args parameter is an optional hash of configuration options.
      def acts_as_authorization_permission_subject(args={}, &block)
        scope = acts_as_authorization_model(args.merge({:permission_subject_class => self.name}), &block)
        zuul_modules << :permission_subject
        include PermissionSubject
      end

      # Configure the model to act as a zuul joining model for roles and subjects
      #
      # The args parameter is an optional hash of configuration options.
      def acts_as_authorization_role_subject(args={}, &block)
        scope = acts_as_authorization_model(args.merge({:role_subject_class => self.name}), &block)
        zuul_modules << :role_subject
        include RoleSubject
      end

      # Sets up the join models for a newly defined scope.
      #
      # This is similar the the acts_as_authorization_* methods, but it handles all the joining models for a scope.
      def prepare_join_classes(scope)
        scope_config = auth_scope(scope).config

        unless auth_scope(scope).role_subject_class.acts_as_authorization_role_subject?
          auth_scope(scope).role_subject_class.instance_eval do
            acts_as_authorization_role_subject(scope_config.to_h)
          end
        end
        
        if auth_scope(scope).config.with_permissions
          unless auth_scope(scope).permission_subject_class.acts_as_authorization_permission_subject?
            auth_scope(scope).permission_subject_class.instance_eval do
              acts_as_authorization_permission_subject(scope_config.to_h)
            end
          end
          unless auth_scope(scope).permission_role_class.acts_as_authorization_permission_role?
            auth_scope(scope).permission_role_class.instance_eval do
              acts_as_authorization_permission_role(scope_config.to_h)
            end
          end
        end
      end


      def acts_as_authorization_model?(type)
        zuul_modules.include?(type)
        #ancestors.include?("zuul/active_record/#{type}".camelize.constantize)
      end

      # Checks if the model is setup to act as a zuul authorization role
      def acts_as_authorization_role?
        acts_as_authorization_model? :role
      end

      # Checks if the model is setup to act as a zuul authorization permission
      def acts_as_authorization_permission?
        acts_as_authorization_model? :permission
      end

      # Checks if the model is setup to act as a zuul authorization context/resource
      def acts_as_authorization_context?
        acts_as_authorization_model? :context
      end

      # Checks if the model is setup to act as a zuul authorization subject
      def acts_as_authorization_subject?
        acts_as_authorization_model? :subject
      end

      # Checks if the model is setup to act as a zuul authorization role_subject
      def acts_as_authorization_role_subject?
        acts_as_authorization_model? :role_subject
      end

      # Checks if the model is setup to act as a zuul authorization permission_subject
      def acts_as_authorization_permission_subject?
        acts_as_authorization_model? :permission_subject
      end

      # Checks if the model is setup to act as a zuul authorization permission_role
      def acts_as_authorization_permission_role?
        acts_as_authorization_model? :permission_role
      end

      def zuul_modules
        @zuul_modules ||= []
      end
    end

    module InstanceMethods
      # Defines acts_as_authorization_*? methods to pass through to the class
      [:role, :permission, :subject, :context, :role_subject, :permission_subject, :permission_role].each do |auth_type|
        method_name = "acts_as_authorization_#{auth_type}?"
        define_method method_name do
          self.class.send method_name
        end
      end
    end

    module AuthorizationMethods
      def self.included(base)
        base.class.send :attr_reader, :auth_scopes
        base.class.send :attr_reader, :current_auth_scope
        base.send :instance_variable_set, :@current_auth_scope, :default
        base.send :extend, ClassMethods
        base.send :include, InstanceMethods
      end

      module ClassMethods
        # Return the requested scope, call a method within a scope, or execute an optional block within that scope
        #
        # If an optional block is passed, it will be executed within the provided scope. This allows
        # you to call methods on the model or the auth scope without having to specify a scope
        # each time. The exec_args hash can be used to pass arguments through to the block.
        #
        # If a block is not passed, exec_args can be used to provide a method and arguments to be called on the
        # object within the requested scope.
        #
        # The reason this is defined separately at the class and instance level is because it uses
        # instance_exec to execute the block within the scope of the object (either class or instance)
        # and then uses method_missing temporarily to provide the auth scope methods.
        def auth_scope(scope=nil, *exec_args, &block)
          scope ||= current_auth_scope
          raise ::Zuul::Exceptions::UndefinedScope unless auth_scopes.has_key?(scope)

          if block_given? || (exec_args.length > 0 && exec_args[0].is_a?(Symbol) && respond_to?(exec_args[0]))
            old_scope = current_auth_scope
            self.current_auth_scope = scope
            
            instance_eval do
              def method_missing (meth,*args)
                return auth_scopes[current_auth_scope].send(meth, *args) if auth_scopes[current_auth_scope].respond_to?(meth)
                raise NoMethodError, "#{self.name}.#{meth} does not exist."
              end
            end
            exec_result = block_given? ? instance_exec(*exec_args, &block) : send(exec_args.slice!(0), *exec_args)
            instance_eval do
              undef method_missing
            end

            self.current_auth_scope = old_scope
            return exec_result
          end

          auth_scopes[scope]
        end

        # Evaluate a block within the requested scope
        def auth_scope_eval(scope=nil, &block)
          auth_scope(scope).instance_eval &block
        end

        # Set the current auth scope
        #
        # The current_auth_scope is the scope that is currently active on the model for all auth operations
        def current_auth_scope=(scope)
          @current_auth_scope = scope.to_sym
        end
      end

      module InstanceMethods
        def self.included(base)
          # TODO figure out how to delegate tasks to self.class
        end

        def auth_scopes
          self.class.auth_scopes
        end

        # Return the requested scope, call a method within a scope, or execute an optional block within that scope
        #
        # If an optional block is passed, it will be executed within the provided scope. This allows
        # you to call methods on the model or the auth scope without having to specify a scope
        # each time. The exec_args hash can be used to pass arguments through to the block.
        #
        # If a block is not passed, exec_args can be used to provide a method and arguments to be called on the
        # object within the requested scope.
        #
        # The reason this is defined separately at the class and instance level is because it uses
        # instance_exec to execute the block within the scope of the object (either class or instance)
        # and then uses method_missing temporarily to provide the auth scope methods.
        def auth_scope(scope=nil, *exec_args, &block)
          scope ||= current_auth_scope
          raise ::Zuul::Exceptions::UndefinedScope unless auth_scopes.has_key?(scope)

          if block_given? || (exec_args.length > 0 && exec_args[0].is_a?(Symbol) && respond_to?(exec_args[0]))
            old_scope = current_auth_scope
            self.current_auth_scope = scope
            
            instance_eval do
              def method_missing (meth,*args)
                return auth_scopes[current_auth_scope].send(meth, *args) if auth_scopes[current_auth_scope].respond_to?(meth)
                raise NoMethodError, "#{self.class.name}##{meth} does not exist."
              end
            end
            exec_result = block_given? ? instance_exec(*exec_args, &block) : send(exec_args.slice!(0), *exec_args)
            instance_eval do
              undef method_missing
            end
            
            self.current_auth_scope = old_scope
            return exec_result
          end

          auth_scopes[scope]
        end

        def auth_scope_eval(scope=nil, &block)
          self.class.auth_scope_eval(scope, &block)
        end

        def current_auth_scope
          self.class.current_auth_scope
        end
        
        def current_auth_scope=(scope)
          self.class.current_auth_scope = scope
        end
        
        # Looks for the role slug with the closest contextual match, working it's way up the context chain.
        #
        # If the provided role is already a Role, just return it without checking for a match.
        #
        # This allows a way to provide a specific role that isn't necessarily the best match 
        # for the provided context to methods like assign_role, but still assign them in the 
        # provided context, letting you assign a role like ['admin', SomeThing, nil] to the
        # resource SomeThing.find(1), even if you also have a ['admin', SomeThing, 1] role.
        def target_role(role, context, force_context=nil)
          auth_scope_eval do
            return role if role.is_a?(role_class)
            force_context ||= config.force_context
            
            context = Zuul::Context.parse(context)
            target_role = role_class.where(:slug => role.to_s.underscore, :context_type => context.class_name, :context_id => context.id).first
            return target_role if force_context
            target_role ||= role_class.where(:slug => role.to_s.underscore, :context_type => context.class_name, :context_id => nil).first unless context.id.nil?
            target_role ||= role_class.where(:slug => role.to_s.underscore, :context_type => nil, :context_id => nil).first unless context.class_name.nil?
            target_role
          end
        end
        
        # Looks for the permission slug with the closest contextual match, working it's way upwards.
        #
        # If the provided permission is already a Permission, just return it without checking for a match.
        #
        # This allows a way to provide a specific permission that isn't necessarily the best match 
        # for the provided context to metods like assign_permission, but still assign them in the 
        # provided context, letting you assign a permission like ['edit', SomeThing, nil] to the
        # resource SomeThing.find(1), even if you also have a ['edit', SomeThing, 1] permission.
        def target_permission(permission, context, force_context=nil)
          auth_scope_eval do
            return permission if permission.is_a?(permission_class)
            force_context ||= config.force_context
            
            context = Zuul::Context.parse(context)
            target_permission = permission_class.where(:slug => permission.to_s.underscore, :context_type => context.class_name, :context_id => context.id).first
            return target_permission if force_context
            target_permission ||= permission_class.where(:slug => permission.to_s.underscore, :context_type => context.class_name, :context_id => nil).first unless context.id.nil?
            target_permission ||= permission_class.where(:slug => permission.to_s.underscore, :context_type => nil, :context_id => nil).first unless context.class_name.nil?
            target_permission
          end
        end
        
        # Verifies whether a role or permission (target) is allowed to be used within the provided context.
        # The target's context must either match the one provided or be higher up the context chain.
        # 
        # [SomeThing, 1] CANNOT be used with [SomeThing, nil] or [OtherThing, 1]
        # [SomeThing, nil] CAN be used for [SomeThing, 1], [SomeThing, 2], etc.
        # [nil, nil] global targets can be used for ANY context
        def verify_target_context(target, context, force_context=nil)
          return false if target.nil?
          force_context ||= auth_scope.config.force_context
          context = Zuul::Context.parse(context)
          force_context ? context == target.context : context <= target.context
        end

        # Simple helper for "IS NULL" vs "= 'VALUE'" SQL syntax
        # (this *must* already exist somewhere in AREL? can't find it though...)
        def sql_is_or_equal(value)
          value.nil? ? "IS" : "="
        end
      end
    end

    # These are included in roles & permissions objects and assigned roles & permissions objects
    # to provide easy access to the context for that object.
    module ContextMethods
      def self.included(base)
        base.send :attr_accessible, :context if ::Zuul
.should_whitelist?
      end

      # Return a Zuul::Context object representing the context for the role
      def context
        Zuul::Context.new(context_type, context_id)
      end

      # Parse a context into an Zuul::Context and set the type and id
      def context=(context)
        context = Zuul::Context.parse(context)
        self.context_type = context.class_name
        self.context_id = context.id
      end
    end

  end
end

ActiveRecord::Base.send :include, Zuul::ActiveRecord
