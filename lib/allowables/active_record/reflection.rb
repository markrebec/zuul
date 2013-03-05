module Allowables
  module ActiveRecord
    module Reflection
      def self.included(base)
        base.send :extend, ClassMethods
        base.send :include, InstanceMethods
      end
      
      # TODO: Could probably just move this stuff to SharedMethods and include in ClassMethods and InstanceMethods
      module ClassMethods
        def self.extended(base)
          # Define dynamic methods to be used for subjects, roles, permissions and their associations.
          # Defines: *_class, *_class_name, *_table_name and *_foreign_key methods.
          # NOTE: Could maybe rework this to use method_missing and define methods dynamically as they're accessed?
          base.class.instance_eval do
            base.auth_config.classes.to_h.each do |class_type,class_name|
              define_method "#{class_type.to_s}_name" do
                if class_name.is_a?(Class)
                  class_name.name
                else
                  class_name.to_s.singularize.camelize
                end
              end
              
              define_method class_type.to_s do
                "::#{send("#{class_type.to_s}_name")}".constantize
              end

              define_method "#{class_type.to_s.gsub(/_class$/,"").pluralize}_table_name" do
                eval("#{class_type.to_s}_name").constantize.table_name
              end
            end

            base.auth_config.primary_classes.to_h.each do |class_type,class_name|
              define_method "#{class_type.to_s.gsub(/_class$/,"")}_foreign_key" do
                "#{eval(class_type.to_s).table_name.singularize}_#{eval(class_type.to_s).primary_key}"
              end
            end
          end
        end
      end

      module InstanceMethods
        def self.included(base)
          # Define dynamic methods that pass through to the corresponding class methods
          # Defines: *_class, *_class_name, *_table_name and *_foreign_key methods.
          base.auth_config.classes.to_h.each do |class_type,class_name|
            [class_type.to_s, "#{class_type.to_s}_name", "#{class_type.to_s.gsub(/_class$/,"").pluralize}_table_name"].each do |meth|
              define_method meth do
                self.class.send(meth)
              end
            end
          end

          base.auth_config.primary_classes.to_h.each do |class_type,class_name|
            define_method "#{class_type.to_s.gsub(/_class$/,"")}_foreign_key" do
              self.class.send("#{class_type.to_s.gsub(/_class$/,"")}_foreign_key")
            end
          end
        end
      end
    end
  end
end
