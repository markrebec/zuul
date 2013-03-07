require 'allowables/active_record/scope'
require 'allowables/active_record/role'
require 'allowables/active_record/permission'
require 'allowables/active_record/context'
require 'allowables/active_record/subject'
require 'allowables/active_record/role_subject'
require 'allowables/active_record/permission_role'
require 'allowables/active_record/permission_subject'

module Allowables
  module ActiveRecord
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end

    module ClassMethods
      def self.extended(base)
        base.class.send :attr_reader, :auth_scopes
      end

      def acts_as_authorization_model(args={}, &block)
        auth_config = Allowables.configuration.clone.configure(args, &block)
        @auth_scopes ||= {}
        raise "Scope already in use: #{args[:scope]}" if @auth_scopes.has_key?(args[:scope])
        @auth_scopes[args[:scope]] = Scope.new(auth_config)
        @auth_scopes[:default] ||= @auth_scopes[auth_config.scope]
        include AuthorizationMethods
      end

      def acts_as_authorization_role(args={}, &block)
        args = {:scope => Allowables.configuration.scope}.merge(args)
        acts_as_authorization_model(args.merge({:role_class => self.name}), &block)
        prepare_join_classes args[:scope]
        include Role 
      end

      def acts_as_authorization_permission(args={}, &block)
        args = {:scope => Allowables.configuration.scope}.merge(args)
        acts_as_authorization_model(args.merge({:permission_class => self.name}), &block)
        prepare_join_classes args[:scope]
        include Permission
      end

      def acts_as_authorization_subject(args={}, &block)
        args = {:scope => Allowables.configuration.scope}.merge(args)
        acts_as_authorization_model(args.merge({:subject_class => self.name}), &block)
        prepare_join_classes args[:scope]
        include Subject
      end

      def acts_as_authorization_context(args={}, &block)
        args = {:scope => Allowables.configuration.scope}.merge(args)
        acts_as_authorization_model(args, &block)
        include Context
      end

      # TODO Maybe rethink how to do this a bit, especially once scopes are introduced. Right now if the same
      # join class is used in two different cases, one with_permissions and one without, they'll step on each
      # other's feet.
      def prepare_join_classes(scope)
        scope_config = auth_scope(scope).config

        unless auth_scope(scope).role_subject_class.ancestors.include?(RoleSubject)
          auth_scope(scope).role_subject_class.instance_eval do
            acts_as_authorization_model(scope_config.to_h)
            include RoleSubject
          end
        end
        
        if auth_scope(scope).config.with_permissions
          unless auth_scope(scope).permission_subject_class.ancestors.include?(PermissionSubject)
            auth_scope(scope).permission_subject_class.instance_eval do
              acts_as_authorization_model(scope_config.to_h)
              include PermissionSubject
            end
          end
          unless auth_scope(scope).permission_role_class.ancestors.include?(PermissionRole)
            auth_scope(scope).permission_role_class.instance_eval do
              acts_as_authorization_model(scope_config.to_h)
              include PermissionRole
            end
          end
        end
      end

      def acts_as_authorization_role?
        ancestors.include?(Allowables::ActiveRecord::Role)
      end

      def acts_as_authorization_permission?
        ancestors.include?(Allowables::ActiveRecord::Permission)
      end

      def acts_as_authorization_context?
        ancestors.include?(Allowables::ActiveRecord::Context)
      end

      def acts_as_authorization_subject?
        ancestors.include?(Allowables::ActiveRecord::Subject)
      end

      def auth_scope(scope=nil, &block)
        scope = @current_auth_scope ||= scope.nil? ? :default : scope

        if block_given?
          old_scope = @current_auth_scope
          @current_auth_scope = scope
          yield
          @current_auth_scope = old_scope
        end

        @auth_scopes[scope]
      end
    end

    module InstanceMethods
      [:role, :permission, :subject, :context].each do |auth_type|
        method_name = "acts_as_authorization_#{auth_type}?"
        define_method method_name do
          self.class.send method_name
        end
      end
    end

    module AuthorizationMethods
      # Convenience method for accessing the @auth_scopes class-level instance variable
      def auth_scopes
        self.class.auth_scopes
      end

      def auth_scope(scope=nil, &block)
        self.class.auth_scope(scope, &block)
      end

      # Looks for the role slug with the closest contextual match, working it's way up the context chain.
      #
      # If the provided role is already a Role, just return it without checking for a match.
      #
      # This allows a way to provide a specific role that isn't necessarily the best match 
      # for the provided context to methods like assign_role, but still assign them in the 
      # provided context, letting you assign a role like ['admin', SomeThing, nil] to the
      # resource SomeThing.find(1), even if you also have a ['admin', SomeThing, 1] role.
      def target_role(role, context)
        return role if role.is_a?(auth_scope.role_class)
        
        context = Allowables::Context.parse(context)
        target_role = auth_scope.role_class.where(:slug => role.to_s.underscore, :context_type => context.class_name, :context_id => context.id).first
        target_role ||= auth_scope.role_class.where(:slug => role.to_s.underscore, :context_type => context.class_name, :context_id => nil).first unless context.id.nil?
        target_role ||= auth_scope.role_class.where(:slug => role.to_s.underscore, :context_type => nil, :context_id => nil).first unless context.class_name.nil?
        target_role
      end
      
      # Looks for the permission slug with the closest contextual match, working it's way upwards.
      #
      # If the provided permission is already a Permission, just return it without checking for a match.
      #
      # This allows a way to provide a specific permission that isn't necessarily the best match 
      # for the provided context to metods like assign_permission, but still assign them in the 
      # provided context, letting you assign a permission like ['edit', SomeThing, nil] to the
      # resource SomeThing.find(1), even if you also have a ['edit', SomeThing, 1] permission.
      def target_permission(permission, context)
        return permission if permission.is_a?(auth_scope.permission_class)
        
        context = Allowables::Context.parse(context)
        target_permission = auth_scope.permission_class.where(:slug => permission.to_s.underscore, :context_type => context.class_name, :context_id => context.id).first
        target_permission ||= auth_scope.permission_class.where(:slug => permission.to_s.underscore, :context_type => context.class_name, :context_id => nil).first unless context.id.nil?
        target_permission ||= auth_scope.permission_class.where(:slug => permission.to_s.underscore, :context_type => nil, :context_id => nil).first unless context.class_name.nil?
        target_permission
      end
      
      # Verifies whether a role or permission (target) is "allowed" to be used within the provided context.
      # The target's context must either match the one provided or be higher up the context chain.
      # 
      # [SomeThing, 1] CANNOT be used with [SomeThing, nil] or [OtherThing, 1]
      # [SomeThing, nil] CAN be used for [SomeThing, 1], [SomeThing, 2], etc.
      # [nil, nil] global targets can be used for ANY context
      #
      # TODO add some options to control whether we go up the chain or not (or how far up)
      def verify_target_context(target, context)
        return false if target.nil?
        context = Allowables::Context.parse(context)
        (target.context.class_name.nil? || target.context.class_name == context.class_name) && (target.context.id.nil? || target.context.id == context.id)
      end

      # Simple helper for "IS NULL" vs "= 'VALUE'" SQL syntax
      # (this *must* already exist somewhere in AREL? can't find it though...)
      def sql_is_or_equal(value)
        value.nil? ? "IS" : "="
      end
    end
  end
end

ActiveRecord::Base.send :include, Allowables::ActiveRecord
