module Allowables
  module ActiveRecord
    module Context
      def self.included(base)
        base.send :extend, ClassMethods
        base.send :include, InstanceMethods
      end

      module ClassMethods
        def self.extended(base)
          base.send :extend, RoleMethods
          base.send :extend, PermissionMethods if base.auth_scope.config.with_permissions
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
      end

      module PermissionMethods
        # Checks whether the subject possesses the specified permission within the context of self
        def allowed_to?(subject, permission)
          subject.has_permission?(permission, self)
        end
      end
    end
  end
end
