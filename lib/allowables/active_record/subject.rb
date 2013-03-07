module Allowables
  module ActiveRecord
    module Subject
      def self.included(base)
        base.send :include, RoleMethods
        base.send(:include, PermissionMethods) if base.auth_scope.config.with_permissions
      end

      module RoleMethods
        def self.included(base)
          base.send :extend, ClassMethods
          base.send :include, InstanceMethods
        end

        module ClassMethods
          def self.extended(base)
            base.send :has_many, base.auth_scope.role_subjects_table_name.to_sym
            base.send :has_many, base.auth_scope.roles_table_name.to_sym, :through => base.auth_scope.role_subjects_table_name.to_sym
          end
        end

        module InstanceMethods
          # Assigns a role to a subject within the provided context.
          #
          # If a Role object is provided it's used directly, otherwise if a role slug
          # is provided, the role is looked up in the context chain by target_role.
          def assign_role(role, context=nil)
            context = Allowables::Context.parse(context)
            target = target_role(role, context)
            return false unless verify_target_context(target, context) && auth_scope.role_subject_class.where(auth_scope.subject_foreign_key.to_sym => id, auth_scope.role_foreign_key.to_sym => target.id, :context_type => context.class_name, :context_id => context.id).limit(1).first.nil?

            return auth_scope.role_subject_class.create(auth_scope.subject_foreign_key.to_sym => id, auth_scope.role_foreign_key.to_sym => target.id, :context_type => context.class_name, :context_id => context.id)
          end

          # Removes a role from a subject within the provided context.
          #
          # If a Role object is provided it's used directly, otherwise if a role slug
          # is provided, the role is looked up in the context chain by target_role.
          def unassign_role(role, context=nil)
            context = Allowables::Context.parse(context)
            target = target_role(role, context)
            return false if target.nil?
            
            assigned_role = auth_scope.role_subject_class.where(auth_scope.subject_foreign_key.to_sym => id, auth_scope.role_foreign_key.to_sym => target.id, :context_type => context.class_name, :context_id => context.id).limit(1).first
            return false if assigned_role.nil?
            assigned_role.destroy
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
            context = Allowables::Context.parse(context)
            target = target_role(role, context)
            return false if target.nil?

            return true unless context.id.nil? || auth_scope.role_subject_class.joins(:role).where(auth_scope.subject_foreign_key.to_sym => id, auth_scope.role_foreign_key.to_sym => target.id, :context_type => context.class_name, :context_id => context.id).first.nil?
            return true unless context.class_name.nil? || auth_scope.role_subject_class.where(auth_scope.subject_foreign_key.to_sym => id, auth_scope.role_foreign_key.to_sym => target.id, :context_type => context.class_name, :context_id => nil).first.nil?
            !auth_scope.role_subject_class.where(auth_scope.subject_foreign_key.to_sym => id, auth_scope.role_foreign_key.to_sym => target.id, :context_type => nil, :context_id => nil).first.nil?
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
            context = Allowables::Context.parse(context)
            target = target_role(role, context)
            return false if target.nil?
            
            return true if has_role?(target, context)
            
            return true unless context.id.nil? || auth_scope.role_subject_class.joins(:role).where(auth_scope.subject_foreign_key.to_sym => id, :context_type => context.class_name, :context_id => context.id).where("roles.level >= ? AND roles.context_type #{sql_is_or_equal(target.context_type)} ? AND roles.context_id #{sql_is_or_equal(target.context_id)} ?", target.level, target.context_type, target.context_id).first.nil?
            return true unless context.class_name.nil? || auth_scope.role_subject_class.joins(:role).where(auth_scope.subject_foreign_key.to_sym => id, :context_type => context.class_name, :context_id => nil).where("roles.level >= ? AND roles.context_type #{sql_is_or_equal(target.context_type)} ? AND roles.context_id #{sql_is_or_equal(target.context_id)} ?", target.level, target.context_type, target.context_id).first.nil?
            !auth_scope.role_subject_class.joins(:role).where(auth_scope.subject_foreign_key.to_sym => id, :context_type => nil, :context_id => nil).where("roles.level >= ? AND roles.context_type #{sql_is_or_equal(target.context_type)} ? AND roles.context_id #{sql_is_or_equal(target.context_id)} ?", target.level, target.context_type, target.context_id).first.nil?
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
            context = Allowables::Context.parse(context)
            auth_scope.role_class.joins(auth_scope.role_subjects_table_name.to_sym).where("#{auth_scope.role_subjects_table_name}.#{auth_scope.subject_foreign_key} = ? AND #{auth_scope.role_subjects_table_name}.context_type #{sql_is_or_equal(context.class_name)} ? AND (#{auth_scope.role_subjects_table_name}.context_id #{sql_is_or_equal(context.id)} ? OR #{auth_scope.role_subjects_table_name}.context_id IS NULL)", id, context.class_name, context.id)
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
            base.send :has_many, base.auth_scope.permission_subjects_table_name.to_sym
            base.send :has_many, base.auth_scope.permissions_table_name.to_sym, :through => base.auth_scope.permission_subjects_table_name.to_sym
          end
        end

        module InstanceMethods
          # Assigns a permission to a subject within the provided context.
          #
          # If a Permission object is provided it's used directly, otherwise if a
          # permission slug is provided, the permission is looked up in the context 
          # chain by target_permission.
          def assign_permission(permission, context=nil)
            context = Allowables::Context.parse(context)
            target = target_permission(permission, context)
            return false unless verify_target_context(target, context) && auth_scope.permission_subject_class.where(auth_scope.subject_foreign_key.to_sym => id, auth_scope.permission_foreign_key.to_sym => target.id, :context_type => context.class_name, :context_id => context.id).limit(1).first.nil?

            return auth_scope.permission_subject_class.create(auth_scope.subject_foreign_key.to_sym => id, auth_scope.permission_foreign_key.to_sym => target.id, :context_type => context.class_name, :context_id => context.id)
          end

          # Removes a permission from a subject within the provided context.
          #
          # If a Permission object is provided it's used directly, otherwise if a
          # permission slug is provided, the permission is looked up in the context 
          # chain by target_permission.
          def unassign_permission(permission, context=nil)
            context = Allowables::Context.parse(context)
            target = target_permission(permission, context)
            return false if target.nil?
            
            assigned_permission = auth_scope.permission_subject_class.where(auth_scope.subject_foreign_key.to_sym => id, auth_scope.permission_foreign_key.to_sym => target.id, :context_type => context.class_name, :context_id => context.id).limit(1).first
            return false if assigned_permission.nil?
            assigned_permission.destroy
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
            context = Allowables::Context.parse(context)
            target = target_permission(permission, context)
            return false if target.nil?

            return true unless context.id.nil? || auth_scope.permission_subject_class.where(auth_scope.subject_foreign_key.to_sym => id, auth_scope.permission_foreign_key.to_sym => target.id, :context_type => context.class_name, :context_id => context.id).first.nil?
            return true unless context.class_name.nil? || auth_scope.permission_subject_class.where(auth_scope.subject_foreign_key.to_sym => id, auth_scope.permission_foreign_key.to_sym => target.id, :context_type => context.class_name, :context_id => nil).first.nil?
            return true unless auth_scope.permission_subject_class.where(auth_scope.subject_foreign_key.to_sym => id, auth_scope.permission_foreign_key.to_sym => target.id, :context_type => nil, :context_id => nil).first.nil?

            return true unless context.id.nil? || auth_scope.permission_role_class.where(auth_scope.role_foreign_key.to_sym => roles_for(context).map(&:id), auth_scope.permission_foreign_key.to_sym => target.id, :context_type => context.class_name, :context_id => context.id).first.nil?
            return true unless context.class_name.nil? || auth_scope.permission_role_class.where(auth_scope.role_foreign_key.to_sym => roles_for(context).map(&:id), auth_scope.permission_foreign_key.to_sym => target.id, :context_type => context.class_name, :context_id => nil).first.nil?
            !auth_scope.permission_role_class.where(auth_scope.role_foreign_key.to_sym => roles_for(context).map(&:id), auth_scope.permission_foreign_key.to_sym => target.id, :context_type => nil, :context_id => nil).first.nil?
          end
          alias_method :permission?, :has_permission?
          alias_method :can?, :has_permission?
          alias_method :allowed_to?, :has_permission?

          # Returns all permissions possessed by the subject within the provided context.
          #
          # This includes permissions assigned directly to the subject or any roles possessed by
          # the subject, as well as all permissions found by looking up the context chain.
          def permissions_for(context=nil)
            context = Allowables::Context.parse(context)
            auth_scope.permission_class.joins("LEFT JOIN #{auth_scope.permission_roles_table_name} ON #{auth_scope.permission_roles_table_name}.#{auth_scope.permission_foreign_key} = permissions.id LEFT JOIN #{auth_scope.permission_subjects_table_name} ON #{auth_scope.permission_subjects_table_name}.#{auth_scope.permission_foreign_key} = permissions.id").where("(#{auth_scope.permission_subjects_table_name}.#{auth_scope.subject_foreign_key} = ? AND #{auth_scope.permission_subjects_table_name}.context_type #{sql_is_or_equal(context.class_name)} ? AND (#{auth_scope.permission_subjects_table_name}.context_id #{sql_is_or_equal(context.id)} ? OR #{auth_scope.permission_subjects_table_name}.context_id IS NULL)) OR (#{auth_scope.permission_roles_table_name}.#{auth_scope.role_foreign_key} IN (?) AND #{auth_scope.permission_roles_table_name}.context_type #{sql_is_or_equal(context.class_name)} ? AND (#{auth_scope.permission_roles_table_name}.context_id #{sql_is_or_equal(context.id)} ? OR #{auth_scope.permission_roles_table_name}.context_id IS NULL))", id, context.class_name, context.id, roles_for(context).map(&:id), context.class_name, context.id)
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
