require 'spec_helper'

describe "Allowables::ActiveRecord::Reflection" do
  before(:each) do
    Dummy.send :include, Allowables::ActiveRecord::Reflection
  end

  describe "set_authorization_class_names" do
    it "should define *_class and *_class_name methods for each authorization class" do
      Dummy.set_authorization_class_names
      Allowables::Configuration::DEFAULT_AUTHORIZATION_CLASSES.keys.each do |ckey|
        Dummy.should respond_to(ckey)
        Dummy.should respond_to("#{ckey}_name")
      end
    end

    it "should use the default authorization classes if none are provided" do
      Dummy.set_authorization_class_names
      Allowables::Configuration::DEFAULT_AUTHORIZATION_CLASSES.keys.each do |ckey|
        Dummy.send(ckey).should == Allowables::Configuration::DEFAULT_AUTHORIZATION_CLASSES[ckey].to_s.camelize.constantize
      end
    end

    it "should merge provided authorization classes with the defaults" do
      Dummy.set_authorization_class_names(:subject_class => :soldier)
      Dummy.subject_class.should == Soldier
      Dummy.role_class.should == Role
    end
    
    it "should redefine the join classes when custom classes are provided" do
      Dummy.set_authorization_class_names(:subject_class => :soldier, :role_class => :rank, :permission_class => :skill)
      Dummy.role_subject_class.should == RankSoldier
      Dummy.permission_subject_class.should == SkillSoldier
      Dummy.permission_role_class.should == RankSkill
    end

    it "should not override join classes that are provided" do
      Dummy.set_authorization_class_names(:role_subject_class => :special_role_user)
      Dummy.role_subject_class.should == SpecialRoleUser
    end
  end
  
  describe "authorization_table_name" do
    it "should require a string class name" do
      Dummy.set_authorization_class_names
      expect { Dummy.authorization_table_name(Role) }.to raise_exception
      expect { Dummy.authorization_table_name('Role') }.to_not raise_exception
    end

    it "should use the Model.table_name to retrieve table names" do
      Dummy.set_authorization_class_names
      Allowables::Configuration::DEFAULT_AUTHORIZATION_CLASSES.each do |ckey,cname|
        Dummy.authorization_table_name(Dummy.send("#{ckey}_name")).should == Dummy.send(ckey).table_name
      end
    end
  end

  describe "*_table_name methods" do
    it "should provide *_table_name methods for each of the authorization classes" do
      Dummy.set_authorization_class_names
      Allowables::Configuration::DEFAULT_AUTHORIZATION_CLASSES.each do |ckey,cname|
        Dummy.should respond_to("#{ckey.to_s.gsub(/_class$/,'').pluralize}_table_name")
      end
    end

    it "should return the correct table name for the model" do
      Dummy.set_authorization_class_names
      Allowables::Configuration::DEFAULT_AUTHORIZATION_CLASSES.each do |ckey,cname|
        Dummy.send("#{ckey.to_s.gsub(/_class$/,'').pluralize}_table_name").should == cname.to_s.camelize.constantize.table_name
      end
    end
  end

  describe "*_foreign_key methods" do
    it "should provide *_foreign_key methods for each of the core authorization classes (subjects, roles and permissions)" do
      Dummy.set_authorization_class_names
      Allowables::Configuration::PRIMARY_AUTHORIZATION_CLASSES.each do |ckey,cname|
        Dummy.should respond_to("#{ckey.to_s.gsub(/_class$/,'')}_foreign_key")
      end
    end

    it "should return the correct foreign_key for the model" do
      Dummy.set_authorization_class_names
      Allowables::Configuration::PRIMARY_AUTHORIZATION_CLASSES.each do |ckey,cname|
        Dummy.send("#{ckey.to_s.gsub(/_class$/,'')}_foreign_key").should == "#{cname.to_s.underscore}_#{cname.to_s.camelize.constantize.primary_key}"
      end
    end
  end

  context "Instance methods" do
    it "should define all *_class, *_class_name, *_table_name and *_foreign_key methods and forward them to the class" do
      Dummy.set_authorization_class_names
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
