require 'spec_helper'

describe "Allowables::ActiveRecord::Reflection" do
  before(:each) do
    Dummy.class.send :attr_reader, :auth_config
    Dummy.send :instance_variable_set, :@auth_config, Allowables::Configuration.new
    Dummy.send :include, Allowables::ActiveRecord::Reflection
  end
  
  it "should define *_class and *_class_name methods for each authorization class" do
    Allowables::Configuration::DEFAULT_AUTHORIZATION_CLASSES.keys.each do |ckey|
      Dummy.should respond_to(ckey)
      Dummy.should respond_to("#{ckey}_name")
    end
  end

  it "should use the default authorization classes if none are provided" do
    Allowables::Configuration::DEFAULT_AUTHORIZATION_CLASSES.keys.each do |ckey|
      Dummy.send(ckey).should == Allowables::Configuration::DEFAULT_AUTHORIZATION_CLASSES[ckey].to_s.camelize.constantize
    end
  end

  describe "*_table_name methods" do
    it "should provide *_table_name methods for each of the authorization classes" do
      Allowables::Configuration::DEFAULT_AUTHORIZATION_CLASSES.each do |ckey,cname|
        Dummy.should respond_to("#{ckey.to_s.gsub(/_class$/,'').pluralize}_table_name")
      end
    end

    it "should return the correct table name for the model" do
      Allowables::Configuration::DEFAULT_AUTHORIZATION_CLASSES.each do |ckey,cname|
        Dummy.send("#{ckey.to_s.gsub(/_class$/,'').pluralize}_table_name").should == cname.to_s.camelize.constantize.table_name
      end
    end
  end

  describe "*_foreign_key methods" do
    it "should provide *_foreign_key methods for each of the core authorization classes (subjects, roles and permissions)" do
      Allowables::Configuration::PRIMARY_AUTHORIZATION_CLASSES.each do |ckey,cname|
        Dummy.should respond_to("#{ckey.to_s.gsub(/_class$/,'')}_foreign_key")
      end
    end

    it "should return the correct foreign_key for the model" do
      Allowables::Configuration::PRIMARY_AUTHORIZATION_CLASSES.each do |ckey,cname|
        Dummy.send("#{ckey.to_s.gsub(/_class$/,'')}_foreign_key").should == "#{cname.to_s.underscore}_#{cname.to_s.camelize.constantize.primary_key}"
      end
    end
  end

  context "Instance methods" do
    it "should define all *_class, *_class_name, *_table_name and *_foreign_key methods and forward them to the class" do
      dummy = Dummy.new
      Allowables::Configuration::DEFAULT_AUTHORIZATION_CLASSES.each do |ckey,cname|
        cmeth = ckey.to_s.gsub(/_class$/,'')
        dummy.should respond_to("#{cmeth}_class")
        dummy.send("#{cmeth}_class").should == Dummy.send("#{cmeth}_class")
        dummy.should respond_to("#{cmeth}_class_name")
        dummy.send("#{cmeth}_class_name").should == Dummy.send("#{cmeth}_class_name")
        dummy.should respond_to("#{cmeth.pluralize}_table_name")
        dummy.send("#{cmeth.pluralize}_table_name").should == Dummy.send("#{cmeth.pluralize}_table_name")
      end
      Allowables::Configuration::PRIMARY_AUTHORIZATION_CLASSES.each do |ckey,cname|
        cmeth = ckey.to_s.gsub(/_class$/,'')
        dummy.should respond_to("#{cmeth}_foreign_key")
        dummy.send("#{cmeth}_foreign_key").should == Dummy.send("#{cmeth}_foreign_key")
      end
    end
  end
end
