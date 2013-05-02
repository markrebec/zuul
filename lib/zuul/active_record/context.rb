module Zuul
  module ActiveRecord
    module Context
      def self.included(base)
        base.send :extend, ClassMethods
        base.send :include, InstanceMethods
      end

      module ClassMethods
        def self.extended(base)
          base.send :extend, RoleMethods
          base.send :before_destroy, :destroy_zuul_roles
          if base.auth_scope.config.with_permissions
            base.send :extend, PermissionMethods
            base.send :before_destroy, :destroy_zuul_permissions
          end
        end
      end

      module InstanceMethods
        def self.included(base)
          base.send :include, RoleMethods
          base.send :include, PermissionMethods if base.auth_scope.config.with_permissions
        end
      end
      
      module RoleMethods
        # Checks whether the subject possesses the specified role within the context of self
        def allowed?(subject, role)
          subject.has_role?(role, self)
        end

        def destroy_zuul_roles
          auth_scopes.each do |name,scope|
            scope.role_class.where(:context_type => self.class.name, :context_id => self.id).each(&:destroy)
            scope.role_subject_class.where(:context_type => self.class.name, :context_id => self.id).each(&:destroy)
          end
        end
      end

      module PermissionMethods
        # Checks whether the subject possesses the specified permission within the context of self
        def allowed_to?(subject, permission)
          subject.has_permission?(permission, self)
        end

        def destroy_zuul_permissions
          auth_scopes.each do |name,scope|
            scope.permission_class.where(:context_type => self.class.name, :context_id => self.id).each(&:destroy)
            scope.permission_role_class.where(:context_type => self.class.name, :context_id => self.id).each(&:destroy)
            scope.permission_subject_class.where(:context_type => self.class.name, :context_id => self.id).each(&:destroy)
          end
        end
      end
    end
  end
end
