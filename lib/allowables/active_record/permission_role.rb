module Allowables
  module ActiveRecord
    module PermissionRole
      def self.included(base)
        base.send :extend, ClassMethods
        base.send :include, InstanceMethods
      end

      module ClassMethods
        def self.extended(base)
          base.send :attr_accessible, :context, :context_id, :context_type, base.permission_foreign_key.to_sym, base.role_foreign_key.to_sym
          add_validations base
          add_associations base
        end

        def self.add_validations(base)
          base.send :validates_presence_of, base.permission_foreign_key.to_sym, base.role_foreign_key.to_sym
          base.send :validates_uniqueness_of, base.permission_foreign_key.to_sym, :scope => [base.role_foreign_key.to_sym, :context_id, :context_type], :case_sensitive => false
          base.send :validates_numericality_of, base.permission_foreign_key.to_sym, base.role_foreign_key.to_sym, :only_integer => true
        end

        def self.add_associations(base)
          base.send :has_many, base.permissions_table_name.to_sym
          base.send :has_many, base.roles_table_name.to_sym
        end
      end

      module InstanceMethods
        # Return a Allowables::Context object representing the context for the permission_role
        def context
          Allowables::Context.new(context_type, context_id)
        end

        # Parse a context into an Allowables::Context and set the type and id
        def context=(context)
          context = Allowables::Context.parse(context)
          self.context_type = context.class_name
          self.context_id = context.id
        end
      end
    end
  end
end
