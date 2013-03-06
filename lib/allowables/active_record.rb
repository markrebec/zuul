require 'allowables/active_record/reflection'
require 'allowables/active_record/role'
require 'allowables/active_record/permission'
require 'allowables/active_record/context'
require 'allowables/active_record/subject'

module Allowables
  module ActiveRecord
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end

    module ClassMethods
      def acts_as_authorization_role(args={}, &block)
        args = {:with_permissions => Allowables.configuration.with_permissions}.merge(args).merge({:role_class => self.name})
        @auth_config = Allowables.configuration.clone.configure(args, &block)
        include AuthorizationMethods
        include Role 
      end

      def acts_as_authorization_permission(args={}, &block)
        args = args.merge({:permission_class => self.name})
        @auth_config = Allowables.configuration.clone.configure(args, &block)
        include AuthorizationMethods
        include Permission
      end

      def acts_as_authorization_context(args={}, &block)
        args = {:with_permissions => Allowables.configuration.with_permissions}.merge(args)
        @auth_config = Allowables.configuration.clone.configure(args, &block)
        include AuthorizationMethods
        include Context
      end

      def acts_as_authorization_subject(args={}, &block)
        args = {:with_permissions => Allowables.configuration.with_permissions}.merge(args).merge({:subject_class => self.name})
        @auth_config = Allowables.configuration.clone.configure(args, &block)
        include AuthorizationMethods
        include Subject
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
      def self.included(base)
        base.class.send :attr_reader, :auth_config
        base.send :extend, ClassMethods
        base.send :include, InstanceMethods
        base.send :include, Reflection
      end

      module InstanceMethods
        # Convenience method for accessing the @auth_config class-level instance variable
        def auth_config
          self.class.auth_config
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
          return role if role.is_a?(role_class)
          
          context = Allowables::Context.parse(context)
          target_role = role_class.where(:slug => role.to_s.underscore, :context_type => context.class_name, :context_id => context.id).first
          target_role ||= role_class.where(:slug => role.to_s.underscore, :context_type => context.class_name, :context_id => nil).first unless context.id.nil?
          target_role ||= role_class.where(:slug => role.to_s.underscore, :context_type => nil, :context_id => nil).first unless context.class_name.nil?
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
          return permission if permission.is_a?(permission_class)
          
          context = Allowables::Context.parse(context)
          target_permission = permission_class.where(:slug => permission.to_s.underscore, :context_type => context.class_name, :context_id => context.id).first
          target_permission ||= permission_class.where(:slug => permission.to_s.underscore, :context_type => context.class_name, :context_id => nil).first unless context.id.nil?
          target_permission ||= permission_class.where(:slug => permission.to_s.underscore, :context_type => nil, :context_id => nil).first unless context.class_name.nil?
          target_permission
        end
        
        # Parses a context into it's two parts: 'type' and 'id'
        #
        # 'type' is a class name (generally an AR model, but can be any class)
        # 'id' is the id of a specific model record, indicating context is an actual record when provided
        #
        # A context can be for a specific record [SomeThing, 1], at the class level [SomeThing, nil], or globally [nil, nil].
        #
        # DEPRECATED
        # TODO: move the tests for this over to the context object
        def parse_context(context)
          return Allowables::Context.parse(context)
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
          (target.context_type.nil? || target.context_type == context.class_name) && (target.context_id.nil? || target.context_id == context.id)
        end

        # Simple helper for "IS NULL" vs "= 'VALUE'" SQL syntax
        # (this *must* already exist somewhere in AREL? can't find it though...)
        def sql_is_or_equal(value)
          value.nil? ? "IS" : "="
        end
      end

      module ClassMethods
      end
    end
  end
end

ActiveRecord::Base.send :include, Allowables::ActiveRecord
