module Allowables
  module ActiveRecord
    module Subject
      def self.included(base)
        base.send :include, RoleMethods
        base.send(:include, PermissionMethods) if base.with_permissions?
      end

      module RoleMethods
        def self.included(base)
          base.send :extend, ClassMethods
          base.send :include, InstanceMethods
        end

        module ClassMethods
          def self.extended(base)
            base.send :has_many, base.role_subjects_table_name.to_sym
            base.send :has_many, base.roles_table_name.to_sym, :through => base.role_subjects_table_name.to_sym
          end
        end

        module InstanceMethods
          # Assigns a role to a subject within the provided context.
          #
          # If a Role object is provided it's used directly, otherwise if a role slug
          # is provided, the role is looked up in the context chain by target_role.
          def assign_role(role, context=nil)
            context_type, context_id = *parse_context(context)
            target = target_role(role, context)
            return false unless verify_target_context(target, context)

            return role_subject_class.create(subject_foreign_key.to_sym => id, :role_id => target.id, :context_type => context_type, :context_id => context_id)
          end

          # Removes a role from a subject within the provided context.
          #
          # If a Role object is provided it's used directly, otherwise if a role slug
          # is provided, the role is looked up in the context chain by target_role.
          def unassign_role(role, context=nil)
            context_type, context_id = *parse_context(context)
            target = target_role(role, context)
            return false if target.nil?

            return role_subject_class.where(subject_foreign_key.to_sym => id, :role_id => target.id, :context_type => context_type, :context_id => context_id).first.destroy
          end
          alias_method :remove_role, :unassign_role

          # Checks whether a subject has a role within the provided context.
          #
          # If a Role object is provided it's used directly, otherwise if a role slug
          # is provided, the role is looked up in the context chain by target_role.
          #
          # The assigned context behaves the same way, in that if the role is not found
          # to belong to the subject with the specified context, we look up the context chain.
          #
          # TODO add options to force context, not go up the chain
          def has_role?(role, context=nil)
            context_type, context_id = *parse_context(context)
            target = target_role(role, context)
            return false if target.nil?

            return true unless role_subject_class.joins(:role).where(subject_foreign_key.to_sym => id, :role_id => target.id, :context_type => context_type, :context_id => context_id).first.nil?
            return false if context_type.nil? # no point in going up the chain
            !role_subject_class.where(subject_foreign_key.to_sym => id, :role_id => target.id, :context_type => context_type, :context_id => nil).first.nil?
          end
          alias_method :role?, :has_role?

          # Checks whether a subject has the specified role or a role with a level greather than
          # that of the specified role, within the provided context.
          #
          # If a Role object is provided it's used directly, otherwise if a role slug
          # is provided, the role is looked up in the context chain by target_role.
          #
          # The assigned context behaves the same way, in that if a matching role is not found
          # to belong to the subject with the specified context, we look up the context chain.
          #
          # TODO add options to force context, not go up the chain
          def has_role_or_higher?(role, context=nil)
            context_type, context_id = *parse_context(context)
            target = target_role(role, context)
            return false if target.nil?
            
            return true if has_role?(target, context)
            
            return true unless role_subject_class.joins(:role).where(subject_foreign_key.to_sym => id, :context_type => context_type, :context_id => context_id).where('roles.level >= ?', target.level).first.nil?
            return false if context_type.nil? # no point in going up the chain
            !role_subject_class.joins(:role).where(subject_foreign_key.to_sym => id, :context_type => context_type, :context_id => nil).where('roles.level >= ?', target.level).first.nil?
          end
          alias_method :role_or_higher?, :has_role_or_higher?
          alias_method :at_least_role?, :has_role_or_higher?

          # Returns the highest level role a subject possesses within the provided context.
          #
          # This includes any roles found by looking up the context chain.
          def highest_role(context=nil)
            return nil unless roles_for?(context)
            roles_for(context).order(:level).reverse_order.limit(1).first
          end

          # Returns all roles possessed by the subject within the provided context.
          #
          # This includes all roles found by looking up the context chain.
          def roles_for(context=nil)
            context_type, context_id = *parse_context(context)
            role_class.joins(role_subjects_table_name.to_sym).where("#{role_subjects_table_name}.#{subject_foreign_key} = ? AND #{role_subjects_table_name}.context_type #{sql_is_or_equal(context_type)} ? AND (#{role_subjects_table_name}.context_id #{sql_is_or_equal(context_id)} ? OR #{role_subjects_table_name}.context_id IS NULL)", id, context_type, context_id)
          end
          
          # Check whether the subject possesses any roles within the specified context.
          #
          # This includes any roles found by looking up the context chain.
          def roles_for?(context=nil)
            roles_for(context).count > 0
          end
        end
      end

      module PermissionMethods
        def self.included(base)
          base.send :extend, ClassMethods
          base.send :include, InstanceMethods
        end

        module ClassMethods
          def self.extended(base)
            base.send :has_many, base.permission_subjects_table_name.to_sym
            base.send :has_many, base.permissions_table_name.to_sym, :through => base.permission_subjects_table_name.to_sym
          end
        end

        module InstanceMethods
          # Assigns a permission to a subject within the provided context.
          #
          # If a Permission object is provided it's used directly, otherwise if a
          # permission slug is provided, the permission is looked up in the context 
          # chain by target_permission.
          def assign_permission(permission, context=nil)
            context_type, context_id = *parse_context(context)
            target = target_permission(permission, context)
            return false unless verify_target_context(target, context)

            return permission_subject_class.create(subject_foreign_key.to_sym => id, :permission_id => target.id, :context_type => context_type, :context_id => context_id)
          end

          # Removes a permission from a subject within the provided context.
          #
          # If a Permission object is provided it's used directly, otherwise if a
          # permission slug is provided, the permission is looked up in the context 
          # chain by target_permission.
          def unassign_permission(permission, context=nil)
            context_type, context_id = *parse_context(context)
            target = target_permission(permission context)
            return false if target.nil?

            return permission_subject_class.where(subject_foreign_key.to_sym => id, :permission_id => target.id, :context_type => context_type, :context_id => context_id).first.destroy
          end
          alias_method :remove_permission, :unassign_permission

          # Checks whether a subject has a permission within the provided context.
          #
          # If a Permission object is provided it's used directly, otherwise if a
          # permission slug is provided, the permission is looked up in the context 
          # chain by target_permission.
          #
          # The assigned context behaves the same way, in that if the permission is not found
          # to belong to the subject with the specified context, we look up the context chain.
          #
          # Permissions belonging to roles possessed by the subject are also included.
          #
          # TODO add options to force context, not go up the chain
          def has_permission?(permission, context=nil)
            context_type, context_id = *parse_context(context)
            target = target_permission(permission, context)
            return false if target.nil?

            return true unless permission_subject_class.where(subject_foreign_key.to_sym => id, :permission_id => target.id, :context_type => context_type, :context_id => context_id).first.nil?

            return true unless permission_role_class.where(:role_id => roles_for(context).map(&:id), :permission_id => target.id, :context_type => context_type, :context_id => context_id).first.nil?
            return false if context_type.nil? # no point in going up the chain
            !permission_role_class.where(:role_id => roles_for(context).map(&:id), :permission_id => target.id, :context_type => context_type, :context_id => nil).first.nil?
          end
          alias_method :permission?, :has_permission?
          alias_method :can?, :has_permission?
          alias_method :allowed_to?, :has_permission?

          # Returns all permissions possessed by the subject within the provided context.
          #
          # This includes permissions assigned directly to the subject or any roles possessed by
          # the subject, as well as all permissions found by looking up the context chain.
          def permissions_for(context=nil)
            context_type, context_id = *parse_context(context)
            permission_class.joins("LEFT JOIN #{permission_roles_table_name} ON #{permission_roles_table_name}.permission_id = permissions.id LEFT JOIN #{permission_subjects_table_name} ON #{permission_subjects_table_name}.permission_id = permissions.id").where("(#{permission_subjects_table_name}.#{subject_foreign_key} = ? AND #{permission_subjects_table_name}.context_type #{sql_is_or_equal(context_type)} ? AND (#{permission_subjects_table_name}.context_id #{sql_is_or_equal(context_id)} ? OR #{permission_subjects_table_name}.context_id IS NULL)) OR (#{permission_roles_table_name}.role_id IN (?) AND #{permission_roles_table_name}.context_type #{sql_is_or_equal(context_type)} ? AND (#{permission_roles_table_name}.context_id #{sql_is_or_equal(context_id)} ? OR #{permission_roles_table_name}.context_id IS NULL))", id, context_type, context_id, roles_for(context).map(&:id), context_type, context_id)
          end
          
          # Check whether the subject possesses any permissions within the specified context.
          #
          # This includes permissions assigned directly to the subject or any roles possessed by
          # the subject, as well as all permissions found by looking up the context chain.
          def permissions_for?(context=nil)
            permissions_for(context).count > 0
          end
        end
      end
    end
  end
end
