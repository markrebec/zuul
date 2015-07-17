require 'rails/generators/active_record'
require 'generators/zuul/orm_helpers'

module ActiveRecord
  module Zuul
    module Generators
      class RoleGenerator < ActiveRecord::Generators::Base
        remove_argument :name, :undefine => true
        argument :name, :type => :string, :default => "Role"
        argument :attributes, :type => :array, :default => [], :banner => "field:type field:type"
        namespace "zuul:role"

        include ::Zuul::Generators::OrmHelpers
        source_root File.expand_path("../templates", __FILE__)

        def copy_role_migration
          if (behavior == :invoke && model_exists?) || (behavior == :revoke && migration_exists?(:role, table_name))
            migration_template "role_existing.rb", "db/migrate/add_zuul_role_to_#{table_name}.rb"
          else
            migration_template "role.rb", "db/migrate/zuul_role_create_#{table_name}.rb"
          end
        end

        def generate_model
          invoke "active_record:model", [name].concat(attributes.map {|attr| "#{attr.name}:#{attr.type}" }), :migration => false unless model_exists? && behavior == :invoke
        end

        def inject_role_content
          content = <<CONTENT
  # Setup authorization for your role model
  acts_as_authorization_role
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
      ## Authorization role columns
      t.string  :slug
      t.integer :level
      t.string  :context_type
      t.integer :context_id
RUBY
        end
      end
    end
  end
end
