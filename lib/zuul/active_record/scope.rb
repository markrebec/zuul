module Zuul
  module ActiveRecord
    class Scope
      attr_reader :config, :name

      protected

      def initialize(config)
        @config = config
        @name = @config.scope
        define_reflection_methods
      end

      # Define dynamic reflection methods that reference the config to be used for subjects, roles, permissions and their associations.
      #
      # With a standard configuration, this defines the following methods:
      #
      # def subject_class                 : Subject
      # def role_class                    : Role
      # def permission_class              : Permission
      # def role_subject_class            : RoleSubject
      # def permission_role_class         : PermissionRole
      #
      # def subject_class_name            : 'Subject'
      # def role_class_name               : 'Role'
      # def permission_class_name         : 'Permission'
      # def role_subject_class_name       : 'RoleSubject'
      # def permission_role_class_name    : 'PermissionRole'
      #
      # def subject_table_name            : 'subjects'
      # def role_table_name               : 'roles'
      # def permission_table_name         : 'permissions'
      # def role_subject_table_name       : 'role_subjects'
      # def permission_role_table_name    : 'permission_roles'
      #
      # def subject_singular_key          : 'subject'
      # def role_singular_key             : 'role'
      # def permission_singular_key       : 'permission'
      # def role_subject_singular_key     : 'role_subject'
      # def permission_role_singular_key  : 'permission_role'
      #
      # def subject_plural_key            : 'subjects'
      # def role_plural_key               : 'roles'
      # def permission_plural_key         : 'permissions'
      # def role_subject_plural_key       : 'role_subjects'
      # def permission_role_plural_key    : 'permission_roles'
      #
      # def subject_foreign_key           : 'subject_id'
      # def role_foreign_key              : 'role_id'
      # def permission_foreign_key        : 'permission_id'
      #
      # All methods are also aliased to pluralized versions, so you can use `subject_class` or `subjects_class`, and
      # when custom class names are used the methods are prefixed with those classes and aliased, so `user_class_name`
      # is aliased to `subject_class_name`
      def define_reflection_methods

        # *_class_name, *_class, *_table_name methods for all classes
        @config.classes.to_h.each do |class_type,class_name|
          class_type_name = class_type.to_s.gsub(/_class$/,'').singularize
          class_eval do
            
            # def CLASS_TYPE_class_name
            define_method "#{class_type_name}_class_name" do
              if @config.send(class_type).is_a?(Class)
                @config.send(class_type).name
              else
                @config.send(class_type).to_s.camelize
              end
            end
            alias_method "#{class_type_name.pluralize}_class_name", "#{class_type_name}_class_name"
            
            # def CLASS_TYPE_class
            define_method "#{class_type_name}_class" do
              "::#{send("#{class_type_name}_class_name")}".constantize
            end
            alias_method "#{class_type_name.pluralize}_class", "#{class_type_name}_class"

            # def CLASS_TYPE_table_name
            define_method "#{class_type_name}_table_name" do
              send("#{class_type_name}_class").table_name
            end
            alias_method "#{class_type_name.pluralize}_table_name", "#{class_type_name}_table_name"

            # def CLASS_TYPE_singular_key (used primarily for associations)
            define_method "#{class_type_name}_singular_key" do
              send("#{class_type_name}_class_name").underscore.split("/").last.singularize.to_sym
            end
            alias_method "#{class_type_name.pluralize}_singular_key", "#{class_type_name}_singular_key"

            # def CLASS_TYPE_plural_key (use primarily for associations)
            define_method "#{class_type_name}_plural_key" do
              send("#{class_type_name}_class_name").underscore.split("/").last.pluralize.to_sym
            end
            alias_method "#{class_type_name.pluralize}_plural_key", "#{class_type_name}_plural_key"
            
            # These define aliases for custom class names, like user_class and user_table_name aliased to subject_class and subject_table_name
            unless class_type.to_s.underscore == "#{class_name.to_s.underscore}_class"
              %w(_class_name _class _table_name _singular_key _plural_key).each do |suffix|
                alias_method "#{class_name.to_s.underscore.singularize}#{suffix}", "#{class_type_name}#{suffix}"
                alias_method "#{class_name.to_s.underscore.pluralize}#{suffix}", "#{class_name.to_s.underscore.singularize}#{suffix}"
              end
            end
          
          end
        end

        # *_foreign_key method for primary classes
        @config.primary_classes.to_h.each do |class_type,class_name|
          class_type_name = class_type.to_s.gsub(/_class$/,'').singularize
          class_eval do
            # def CLASS_TYPE_foreign_key
            define_method "#{class_type_name}_foreign_key" do
              # This is hideous, but we need some sort of fallback for cases like Rails 4 Heroku deploys where the environment and
              # database are not available.
              begin
                "#{send("#{class_type_name}_table_name").singularize}_#{send("#{class_type_name}_class").primary_key}"
              rescue
                "#{send("#{class_type_name}_table_name").singularize}_id"
              end
            end
            alias_method "#{class_type.to_s.gsub(/_class$/,"").pluralize}_foreign_key", "#{class_type.to_s.gsub(/_class$/,"").singularize}_foreign_key"
            
            unless class_type.to_s.underscore == "#{class_name.to_s.underscore}_class"
              alias_method "#{class_name.to_s.underscore.singularize}_foreign_key", "#{class_type.to_s.gsub(/_class$/,"").singularize}_foreign_key" # CLASS_NAME_foreign_key
              alias_method "#{class_name.to_s.underscore.pluralize}_foreign_key", "#{class_name.to_s.underscore.singularize}_foreign_key"
            end
          end
        end
      end
    end
  end
end
