module Allowables
  module ActiveRecord
    module Reflection
      def self.included(base)
        base.send :extend, ClassMethods
        base.send :include, InstanceMethods
      end

      module ClassMethods
        # Set the classes to be used for subjects, roles, permissions and their associations
        # NOTE: Doesn't actually "set" any variables, but defines methods like role_class_name
        def set_authorization_class_names(classes={})
          auth_classes = Allowables::Configuration::DEFAULT_AUTHORIZATION_CLASSES.merge(classes.select { |k,v| Allowables::Configuration::DEFAULT_AUTHORIZATION_CLASSES.keys.include?(k) })
          [[:role, :subject], [:permission, :subject], [:permission, :role]].each do |join_types|
            join_key = "#{join_types[0].to_s}_#{join_types[1].to_s}_class".to_sym
            next if classes.has_key?(join_key) # don't override join table if it was provided

            join_classes = join_types.map do |class_type|
              type_class = auth_classes["#{class_type.to_s}_class".to_sym]
              if type_class.is_a?(Class)
                type_class.name.underscore
              else
                type_class.to_s.singularize.underscore
              end
            end
            join_classes.sort!
            auth_classes[join_key] = join_classes.map(&:to_s).map(&:singularize).map(&:underscore).join("_")
          end
          
          self.class.instance_eval do
            auth_classes.each do |class_type,c|
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
        # Defines the TYPE_class, TYPE_class_name, TYPES_table_name and TYPE_foreign_key
        # methods for the default authorization class types.
        # TODO could probably just use method_missing here? might be a little less efficient
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
