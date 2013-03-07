module Allowables
  module ActiveRecord
    class Scope
      attr_reader :config, :name

      protected

      def initialize(config)
        @config = config
        @name = @config.scope
        define_reflection_methods
        super()
      end

      # Define dynamic reflection methods that reference the config to be used for subjects, roles, permissions and their associations.
      def define_reflection_methods
        # *_class_name, *_class, *_table_name methods for all classes
        @config.classes.to_h.each do |class_type,class_name|
          class_eval do
            # def CLASS_TYPE_class_name
            define_method "#{class_type.to_s}_name" do
              if @config.send(class_type).is_a?(Class)
                @config.send(class_type).name
              else
                @config.send(class_type).to_s.singularize.camelize
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
            alias_method "#{class_type.to_s.gsub(/_class$/,"").singularize}_table_name", "#{class_type.to_s.gsub(/_class$/,"").pluralize}_table_name"
            
            unless class_type.to_s.underscore == "#{class_name.to_s.underscore}_class"
              # def CLASS_NAME_class_name
              alias_method "#{class_name.to_s.underscore}_class_name", "#{class_type.to_s}_name"
              
              # def CLASS_NAME_class
              alias_method "#{class_name.to_s.underscore}_class", class_type
              
              # def CLASS_NAME_table_name
              alias_method "#{class_name.to_s.underscore.pluralize}_table_name", "#{class_type.to_s.gsub(/_class$/,"").pluralize}_table_name"
            end
          end
        end

        # *_foreign_key method for primary classes
        @config.primary_classes.to_h.each do |class_type,class_name|
          class_eval do
            # def CLASS_TYPE_foreign_key
            define_method "#{class_type.to_s.gsub(/_class$/,"").singularize}_foreign_key" do
              "#{send(class_type.to_s).table_name.singularize}_#{send(class_type.to_s).primary_key}"
            end
            alias_method "#{class_type.to_s.gsub(/_class$/,"").pluralize}_foreign_key", "#{class_type.to_s.gsub(/_class$/,"").singularize}_foreign_key"
            
            unless class_type.to_s.underscore == "#{class_name.to_s.underscore}_class"
              # def CLASS_NAME_foreign_key
              alias_method "#{class_name.to_s.underscore.singularize}_foreign_key", "#{class_type.to_s.gsub(/_class$/,"").singularize}_foreign_key"
              alias_method "#{class_name.to_s.underscore.pluralize}_foreign_key", "#{class_name.to_s.underscore.singularize}_foreign_key"
            end
          end
        end
      end
    end
  end
end
