module Allowables
  module ActiveRecord
    module Permission
      def self.included(base)
        base.send :extend, ClassMethods
        base.send :include, InstanceMethods
      end

      module ClassMethods
        def self.extended(base)
          add_validations base
          add_associations base
        end

        def self.add_validations(base)
          base.send :validates_presence_of, :name, :slug
          base.send :validates_uniqueness_of, :slug, :scope => [:context_id, :context_type], :case_sensitive => false
          base.send :validates_format_of, :slug, :with => /\A[a-z0-9_]+\Z/
        end

        def self.add_associations(base)
          base.send :has_many, base.permission_roles_table_name.to_sym
          base.send :has_many, base.roles_table_name.to_sym, :through => base.permission_roles_table_name.to_sym
          base.send :has_many, base.permission_subjects_table_name.to_sym
          base.send :has_many, base.subjects_table_name.to_sym, :through => base.permission_subjects_table_name.to_sym
        end
      end

      module InstanceMethods
        def self.included(base)
        end
      end
    end
  end
end
