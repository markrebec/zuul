module Allowables
  module ActiveRecord
    class Scope
      attr_reader :config

      protected

      def initialize(config)
        @config = config
        define_reflection_methods
        super()
      end

      # Define dynamic reflection methods to be used for subjects, roles, permissions and their associations.
      def define_reflection_methods
        scope_config = @config
        class_eval do
          scope_config.classes.to_h.each do |class_type,class_name|
            # def CLASS_TYPE_class_name
            define_method "#{class_type.to_s}_name" do
              if class_name.is_a?(Class)
                class_name.name
              else
                class_name.to_s.singularize.camelize
              end
            end
            
            # def CLASS_TYPE_class
            define_method class_type.to_s do
              "::#{send("#{class_type.to_s}_name")}".constantize
            end

            # def CLASS_TYPE_table_name
            define_method "#{class_type.to_s.gsub(/_class$/,"").pluralize}_table_name" do
              send("#{class_type.to_s}_name").constantize.table_name
            end
            
            unless class_type.to_s.underscore == "#{class_name.to_s.underscore}_class"
              # def CLASS_NAME_class_name
              define_method "#{class_name.to_s.underscore}_class_name" do
                send("#{class_type.to_s}_name")
              end
              
              # def CLASS_NAME_class
              define_method "#{class_name.to_s.underscore}_class" do
                send(class_type)
              end
              
              # def CLASS_NAME_table_name
              define_method "#{class_name.to_s.underscore.pluralize}_table_name" do
                send("#{class_type.to_s.gsub(/_class$/,"").pluralize}_table_name")
              end
            end
          end

          scope_config.primary_classes.to_h.each do |class_type,class_name|
            # def CLASS_TYPE_foreign_key
            define_method "#{class_type.to_s.gsub(/_class$/,"")}_foreign_key" do
              "#{send(class_type.to_s).table_name.singularize}_#{send(class_type.to_s).primary_key}"
            end
            
            unless class_type.to_s.underscore == "#{class_name.to_s.underscore}_class"
              # def CLASS_NAME_foreign_key
              define_method "#{class_name.to_s.underscore}_foreign_key" do
                send("#{class_type.to_s.gsub(/_class$/,"")}_foreign_key")
              end
            end
          end
        end
      end
    end
  end
end
