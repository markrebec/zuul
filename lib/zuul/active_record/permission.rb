module Zuul
  module ActiveRecord
    module Permission
      def self.included(base)
        base.send :extend, ClassMethods
        base.send :include, ContextMethods # defined in lib/zuul/active_record.rb
      end

      module ClassMethods
        def self.extended(base)
          base.send :attr_accessible, :context, :context_id, :context_type, :slug
          add_validations base
          add_associations base
        end

        def self.add_validations(base)
          base.send :validates_presence_of, :slug
          base.send :validates_uniqueness_of, :slug, :scope => [:context_id, :context_type], :case_sensitive => false
          base.send :validates_format_of, :slug, :with => /\A[a-z0-9_]+\Z/
        end

        def self.add_associations(base)
          base.send :has_many, base.auth_scope.permission_roles_table_name.to_sym
          base.send :has_many, base.auth_scope.roles_table_name.to_sym, :through => base.auth_scope.permission_roles_table_name.to_sym
          base.send :has_many, base.auth_scope.permission_subjects_table_name.to_sym
          base.send :has_many, base.auth_scope.subjects_table_name.to_sym, :through => base.auth_scope.permission_subjects_table_name.to_sym
        end
      end
    end
  end
end
