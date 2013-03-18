require 'spec_helper'

describe "Zuul::ActiveRecord::Scope" do
  it "should require an auth config to be initialized" do
    scope = Zuul::ActiveRecord::Scope.new(Zuul::Configuration.new)
    scope.should be_an_instance_of(Zuul::ActiveRecord::Scope)
  end

  context "class reflections" do
    before(:each) do
      @scope = Zuul::ActiveRecord::Scope.new(Zuul::Configuration.new)
    end

    context "class type methods" do
      it "should define *_class_name methods for each of the class types" do
        Zuul::Configuration::DEFAULT_AUTHORIZATION_CLASSES.keys.each do |class_type|
          @scope.should respond_to("#{class_type.to_s.gsub(/_class$/,'').singularize}_class_name")
        end
      end

      it "should define *_class methods for each of the class types" do
        Zuul::Configuration::DEFAULT_AUTHORIZATION_CLASSES.keys.each do |class_type|
          @scope.should respond_to("#{class_type.to_s.gsub(/_class$/,'').singularize}_class")
        end
      end

      it "should define *_table_name methods for each of the class types" do
        Zuul::Configuration::DEFAULT_AUTHORIZATION_CLASSES.keys.each do |class_type|
          @scope.should respond_to("#{class_type.to_s.gsub(/_class$/,'').singularize}_table_name")
        end
      end

      it "should define *_foreign_key methods for each of the primary class types" do
        Zuul::Configuration::PRIMARY_AUTHORIZATION_CLASSES.keys.each do |class_type|
          @scope.should respond_to("#{class_type.to_s.gsub(/_class$/,'').singularize}_foreign_key")
        end
      end

      it "should alias pluralized versions of each method" do
        Zuul::Configuration::DEFAULT_AUTHORIZATION_CLASSES.keys.each do |class_type|
          @scope.should respond_to("#{class_type.to_s.gsub(/_class$/,'').pluralize}_class_name")
          @scope.should respond_to("#{class_type.to_s.gsub(/_class$/,'').pluralize}_class")
          @scope.should respond_to("#{class_type.to_s.gsub(/_class$/,'').pluralize}_table_name")
        end
        Zuul::Configuration::PRIMARY_AUTHORIZATION_CLASSES.keys.each do |class_type|
          @scope.should respond_to("#{class_type.to_s.gsub(/_class$/,'').pluralize}_foreign_key")
        end
      end
    end

    context "class name methods" do
      it "should alias class name methods to the class type equivalent" do
        Zuul::Configuration::DEFAULT_AUTHORIZATION_CLASSES.keys.each do |class_type|
          @scope.should respond_to("#{@scope.config.send(class_type).to_s.singularize}_class_name")
          @scope.should respond_to("#{@scope.config.send(class_type).to_s.singularize}_class")
          @scope.should respond_to("#{@scope.config.send(class_type).to_s.singularize}_table_name")
        end
        Zuul::Configuration::PRIMARY_AUTHORIZATION_CLASSES.keys.each do |class_type|
          @scope.should respond_to("#{@scope.config.send(class_type).to_s.singularize}_foreign_key")
        end
      end

      it "should alias plurlized versions of each method" do
        Zuul::Configuration::DEFAULT_AUTHORIZATION_CLASSES.keys.each do |class_type|
          @scope.should respond_to("#{@scope.config.send(class_type).to_s.underscore.pluralize}_class_name")
          @scope.should respond_to("#{@scope.config.send(class_type).to_s.underscore.pluralize}_class")
          @scope.should respond_to("#{@scope.config.send(class_type).to_s.underscore.pluralize}_table_name")
        end
        Zuul::Configuration::PRIMARY_AUTHORIZATION_CLASSES.keys.each do |class_type|
          @scope.should respond_to("#{@scope.config.send(class_type).to_s.underscore.pluralize}_foreign_key")
        end
      end
    end
  end
end
