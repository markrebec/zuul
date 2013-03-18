require 'rails/generators/active_record'
require 'generators/zuul/orm_helpers'

module ActiveRecord
  module Zuul
    module Generators
      class PermissionGenerator < ActiveRecord::Generators::Base
        argument :attributes, :type => :array, :default => [], :banner => "field:type field:type"
        namespace "zuul:permission"

        include ::Zuul::Generators::OrmHelpers
        source_root File.expand_path("../templates", __FILE__)

        def copy_zuul_migration
          if (behavior == :invoke && model_exists?) || (behavior == :revoke && migration_exists?(:permission, table_name))
            migration_template "permission_existing.rb", "db/migrate/add_zuul_permission_to_#{table_name}"
          else
            migration_template "permission.rb", "db/migrate/zuul_permission_create_#{table_name}"
          end
        end

        def generate_model
          invoke "active_record:model", [name], :migration => false unless model_exists? && behavior == :invoke
        end

        def inject_zuul_content
        content = <<CONTENT
  # Setup authorization for your permission model
  acts_as_authorization_permission
CONTENT

          class_path = if namespaced?
            class_name.to_s.split("::")
          else
            [class_name]
          end

          indent_depth = class_path.size - 1
          content = content.split("\n").map { |line| "  " * indent_depth + line } .join("\n") << "\n"

          inject_into_class(model_path, class_path.last, content) if model_exists?
        end

        def migration_data
<<RUBY
      # Authorization permission columns
      t.string  :slug
      t.string  :context_type
      t.integer :context_id
RUBY
        end
      end
    end
  end
end
