module Zuul
  module ActiveRecord
    module Role
      def self.included(base)
        base.send :extend, ClassMethods
        base.send :include, ContextMethods # defined in lib/zuul/active_record.rb
        base.send :include, InstanceMethods
        base.send :include, PermissionMethods if base.auth_scope.config.with_permissions
      end

      module ClassMethods
        def self.extended(base)
          base.send :attr_accessible, :context_id, :context_type, :level, :slug
          add_validations base
          add_associations base
        end

        def self.add_validations(base)
          base.send :validates_presence_of, :level, :slug
          base.send :validates_uniqueness_of, :slug, :scope => [:context_id, :context_type], :case_sensitive => false
          base.send :validates_format_of, :slug, :with => /\A[a-z0-9_]+\Z/
          base.send :validates_uniqueness_of, :level, :scope => [:context_id, :context_type]
          base.send :validates_numericality_of, :level, :only_integer => true
        end

        def self.add_associations(base)
          base.send :has_many, base.auth_scope.role_subjects_table_name.to_sym, :dependent => :destroy
          base.send :has_many, base.auth_scope.subjects_table_name.to_sym, :through => base.auth_scope.role_subjects_table_name.to_sym
          if base.auth_scope.config.with_permissions
            base.send :has_many, base.auth_scope.permission_roles_table_name.to_sym, :dependent => :destroy
            base.send :has_many, base.auth_scope.permissions_table_name.to_sym, :through => base.auth_scope.permission_roles_table_name.to_sym
          end
        end
      end

      module InstanceMethods
        # Returns a list of contexts within which the role has been assigned to subjects
        def assigned_contexts
          auth_scope do
            send(role_subjects_table_name.to_sym).group(:context_type, :context_id).map(&:context)
          end
        end
      end

      module PermissionMethods
        # Assigns a permission to a role within the provided context.
        #
        # If a Permission object is provided it's used directly, otherwise if a
        # permission slug is provided, the permission is looked up in the context 
        # chain by target_permission.
        def assign_permission(permission, context=nil, force_context=nil)
          auth_scope do
            context = Zuul::Context.parse(context)
            target = target_permission(permission, context, force_context)
            return false unless verify_target_context(target, context, force_context) && verify_target_context(self, context, false) && permission_role_class.where(role_foreign_key.to_sym => id, permission_foreign_key.to_sym => target.id, :context_type => context.class_name, :context_id => context.id).limit(1).first.nil?

            return permission_role_class.create(role_foreign_key.to_sym => id, permission_foreign_key.to_sym => target.id, :context_type => context.class_name, :context_id => context.id)
          end
        end

        # Removes a permission from a role within the provided context.
        #
        # If a Permission object is provided it's used directly, otherwise if a
        # permission slug is provided, the permission is looked up in the context 
        # chain by target_permission.
        def unassign_permission(permission, context=nil, force_context=nil)
          auth_scope do
            context = Zuul::Context.parse(context)
            target = target_permission(permission, context, force_context)
            return false if target.nil?

            assigned_permission = permission_role_class.where(role_foreign_key.to_sym => id, permission_foreign_key.to_sym => target.id, :context_type => context.class_name, :context_id => context.id).limit(1).first
            return false if assigned_permission.nil?
            return assigned_permission.destroy
          end
        end
        alias_method :remove_permission, :unassign_permission

        # Checks whether a role has a permission within the provided context.
        #
        # If a Permission object is provided it's used directly, otherwise if a
        # permission slug is provided, the permission is looked up in the context 
        # chain by target_permission.
        #
        # The assigned context behaves the same way, in that if the permission is not found
        # to belong to the role with the specified context, we look up the context chain.
        #
        # TODO add options to force context, not go up the chain
        def has_permission?(permission, context=nil, force_context=nil)
          auth_scope do
            force_context ||= config.force_context
            context = Zuul::Context.parse(context)
            target = target_permission(permission, context, force_context)
            return false if target.nil?

            return true unless (context.id.nil? && !force_context) || permission_role_class.where(role_foreign_key.to_sym => id, permission_foreign_key.to_sym => target.id, :context_type => context.class_name, :context_id => context.id).first.nil?
            unless force_context
              return true unless context.class_name.nil? || permission_role_class.where(role_foreign_key.to_sym => id, permission_foreign_key.to_sym => target.id, :context_type => context.class_name, :context_id => nil).first.nil?
              return !permission_role_class.where(role_foreign_key.to_sym => id, permission_foreign_key.to_sym => target.id, :context_type => nil, :context_id => nil).first.nil?
            end
          end
        end
        alias_method :permission?, :has_permission?
        alias_method :can?, :has_permission?
        alias_method :allowed_to?, :has_permission?
        
        # Returns all permissions possessed by the role within the provided context.
        def permissions_for(context=nil, force_context=nil)
          auth_scope do
            force_context ||= config.force_context
            context = Zuul::Context.parse(context)
            if force_context
              return permission_class.joins(permission_roles_table_name.to_sym).where(permission_roles_table_name.to_sym => {role_foreign_key.to_sym => id, :context_type => context.class_name, :context_id => context.id})
            else
              return permission_class.joins("LEFT JOIN #{permission_roles_table_name} ON #{permission_roles_table_name}.#{permission_foreign_key} = #{permissions_table_name}.id").where("#{permission_roles_table_name}.#{role_foreign_key} = ? AND (#{permission_roles_table_name}.context_type #{sql_is_or_equal(context.class_name)} ? OR #{permission_roles_table_name}.context_type IS NULL) AND (#{permission_roles_table_name}.context_id #{sql_is_or_equal(context.id)} ? OR #{permission_roles_table_name}.context_id IS NULL)", id, context.class_name, context.id)
            end
          end
        end
        
        # Check whether the role possesses any permissions within the specified context.
        def permissions_for?(context=nil, force_context=nil)
          permissions_for(context, force_context).count > 0
        end
      end
    end
  end
end
