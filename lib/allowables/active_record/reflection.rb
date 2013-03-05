module Allowables
  module ActiveRecord
    module Reflection
      def self.included(base)
        base.send :extend, ClassMethods
        base.send :include, InstanceMethods
      end

      module ClassMethods
        def self.extended(base)
          # Set the classes to be used for subjects, roles, permissions and their associations
          # NOTE: Doesn't actually "set" any variables, but defines methods like role_class_name
          # NOTE: Should maybe rework this to use method_missing and define methods dynamically as they're accessed?
          base.class.instance_eval do
            base.auth_config.classes.to_h.each do |class_type,c|
              define_method "#{class_type.to_s}_name" do
                if c.is_a?(Class)
                  c.name
                else
                  c.to_s.singularize.camelize
                end
              end
              
              define_method "#{class_type.to_s}" do
                "::#{send("#{class_type.to_s}_name")}".constantize
              end
            end

            # TODO define *_table_name methods, *_foreign_key methods for primary classes
          end
        end

        def authorization_table_name(class_name)
          class_name.constantize.table_name
        end
        
        def subjects_table_name
          authorization_table_name(subject_class_name)
        end

        def roles_table_name
          authorization_table_name(role_class_name)
        end

        def permissions_table_name
          authorization_table_name(permission_class_name)
        end

        def role_subjects_table_name
          authorization_table_name(role_subject_class_name)
        end

        def permission_subjects_table_name
          authorization_table_name(permission_subject_class_name)
        end

        def permission_roles_table_name
          authorization_table_name(permission_role_class_name)
        end

        def role_foreign_key
          "#{role_class_name.underscore}_#{role_class.primary_key}"
        end

        def permission_foreign_key
          "#{permission_class_name.underscore}_#{permission_class.primary_key}"
        end

        def subject_foreign_key
          "#{subject_class_name.underscore}_#{subject_class.primary_key}"
        end
      end

      module InstanceMethods
        # Defines the TYPE_class, TYPE_class_name, TYPES_table_name and TYPE_foreign_key methods for the default authorization class types.
        # TODO could probably just use method_missing here? might be a little less efficient, maybe define the methods as they're accessed
        def self.included(base)
          Allowables::Configuration::DEFAULT_AUTHORIZATION_CLASSES.keys.each do |method_class|
            methods = ["#{method_class.to_s}", "#{method_class.to_s}_name", "#{method_class.to_s.gsub(/_class$/,'').pluralize}_table_name"]
            methods << "#{method_class.to_s.gsub(/_class$/,'')}_foreign_key" if Allowables::Configuration::PRIMARY_AUTHORIZATION_CLASSES.keys.include?(method_class)
            methods.each do |method_name|
              define_method method_name do
                self.class.send method_name
              end
            end
          end
        end
      end
    end
  end
end
