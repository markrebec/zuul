require 'rails/generators/active_record'
require 'generators/zuul/orm_helpers'

module ActiveRecord
  module Zuul
    module Generators
      class PermissionSubjectGenerator < ActiveRecord::Generators::Base
        remove_argument :name, :undefine => true
        argument :permission_model, :type => :string, :default => "Permission"
        argument :subject_model, :type => :string, :default => "User"
        argument :attributes, :type => :array, :default => [], :banner => "field:type field:type"
        namespace "zuul:permission_subject"

        include ::Zuul::Generators::OrmHelpers
        source_root File.expand_path("../templates", __FILE__)

        def name
          [permission_model, subject_model].sort.map(&:to_s).map(&:camelize).map(&:singularize).join("")
        end

        def copy_permission_subject_migration
          attributes << Rails::Generators::GeneratedAttribute.new("#{permission_model.to_s.underscore.singularize}_id", :integer)
          attributes << Rails::Generators::GeneratedAttribute.new("#{subject_model.to_s.underscore.singularize}_id", :integer)
          attributes << Rails::Generators::GeneratedAttribute.new("context_type", :string)
          attributes << Rails::Generators::GeneratedAttribute.new("context_id", :integer)

          if (behavior == :invoke && model_exists?) || (behavior == :revoke && migration_exists?(:permission_subject, table_name))
            migration_template "permission_subject_existing.rb", "db/migrate/add_zuul_permission_subject_to_#{table_name}.rb"
          else
            migration_template "permission_subject.rb", "db/migrate/zuul_permission_subject_create_#{table_name}.rb"
          end
        end

        def generate_model
          invoke "active_record:model", [name].concat(attributes.map {|attr| "#{attr.name}:#{attr.type}" }), :migration => false unless model_exists? && behavior == :invoke
        end
      end
    end
  end
end
