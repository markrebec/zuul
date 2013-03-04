require 'spec_helper'

describe "Allowables::Configuration" do
  before(:each) do
    @config = Allowables::Configuration.new
  end

  it "should provide constants defining default attributes and values" do
    expect { Allowables::Configuration::PRIMARY_AUTHORIZATION_CLASSES }.to_not raise_exception
    expect { Allowables::Configuration::AUTHORIZATION_JOIN_CLASSES }.to_not raise_exception
    expect { Allowables::Configuration::DEFAULT_AUTHORIZATION_CLASSES }.to_not raise_exception
    expect { Allowables::Configuration::DEFAULT_CONFIGURATION_OPTIONS }.to_not raise_exception
  end

  it "should ensure all defined defaults are accessible attributes" do
    [Allowables::Configuration::DEFAULT_AUTHORIZATION_CLASSES, Allowables::Configuration::DEFAULT_CONFIGURATION_OPTIONS].each do |opts|
      opts.each do |key,val|
        @config.should respond_to(key)
      end
    end
  end

  it "should initialize with defaults from the defined constants" do
    [Allowables::Configuration::DEFAULT_AUTHORIZATION_CLASSES, Allowables::Configuration::DEFAULT_CONFIGURATION_OPTIONS].each do |opts|
      opts.each do |key,val|
        @config.send(key).should == val
      end
    end
  end
  
  describe "PRIMARY_AUTHORIZATION_CLASSES" do
    it "should define the :subject_class option" do
      Allowables::Configuration::PRIMARY_AUTHORIZATION_CLASSES.has_key?(:subject_class).should be_true
      Allowables::Configuration::PRIMARY_AUTHORIZATION_CLASSES[:subject_class].should == :user
    end
    
    it "should define the :role_class option" do
      Allowables::Configuration::PRIMARY_AUTHORIZATION_CLASSES.has_key?(:role_class).should be_true
      Allowables::Configuration::PRIMARY_AUTHORIZATION_CLASSES[:role_class].should == :role
    end
    
    it "should define the :permission_class option" do
      Allowables::Configuration::PRIMARY_AUTHORIZATION_CLASSES.has_key?(:permission_class).should be_true
      Allowables::Configuration::PRIMARY_AUTHORIZATION_CLASSES[:permission_class].should == :permission
    end
  end
  
  describe "AUTHORIZATION_JOIN_CLASSES" do
    it "should define the :role_subject_class option" do
      Allowables::Configuration::AUTHORIZATION_JOIN_CLASSES.has_key?(:role_subject_class).should be_true
      Allowables::Configuration::AUTHORIZATION_JOIN_CLASSES[:role_subject_class].should == :role_user
    end
    
    it "should define the :permission_role_class option" do
      Allowables::Configuration::AUTHORIZATION_JOIN_CLASSES.has_key?(:permission_role_class).should be_true
      Allowables::Configuration::AUTHORIZATION_JOIN_CLASSES[:permission_role_class].should == :permission_role
    end
    
    it "should define the :permission_subject_class option" do
      Allowables::Configuration::AUTHORIZATION_JOIN_CLASSES.has_key?(:permission_subject_class).should be_true
      Allowables::Configuration::AUTHORIZATION_JOIN_CLASSES[:permission_subject_class].should == :permission_user
    end
  end
  
  describe "DEFAULT_AUTHORIZATION_CLASSES" do
    it "should combine the PRIMARY_AUTHORIZATION_CLASSES and AUTHORIZATION_JOIN_CLASSES" do
      [Allowables::Configuration::PRIMARY_AUTHORIZATION_CLASSES, Allowables::Configuration::AUTHORIZATION_JOIN_CLASSES].each do |classes|
        classes.each do |key,val|
          Allowables::Configuration::DEFAULT_AUTHORIZATION_CLASSES.has_key?(key).should be_true
          Allowables::Configuration::DEFAULT_AUTHORIZATION_CLASSES[key].should == val
        end
      end
    end
  end
  
  describe "DEFAULT_CONFIGURATION_OPTIONS" do
    it "should define the :acl_default option" do
      Allowables::Configuration::DEFAULT_CONFIGURATION_OPTIONS.has_key?(:acl_default).should be_true
      Allowables::Configuration::DEFAULT_CONFIGURATION_OPTIONS[:acl_default].should == :deny
    end
    
    it "should define the :subject_method option" do
      Allowables::Configuration::DEFAULT_CONFIGURATION_OPTIONS.has_key?(:subject_method).should be_true
      Allowables::Configuration::DEFAULT_CONFIGURATION_OPTIONS[:subject_method].should == :current_user
    end

    it "should define the :with_permissions option" do
      Allowables::Configuration::DEFAULT_CONFIGURATION_OPTIONS.has_key?(:with_permissions).should be_true
      Allowables::Configuration::DEFAULT_CONFIGURATION_OPTIONS[:with_permissions].should == true
    end
  end

  describe "#configure" do
    it "should allow setting config vars via the passed config object" do
      @config.configure do |config|
        config.subject_method = :config_current_user
      end
      @config.subject_method.should == :config_current_user
    end

    it "should allow setting config vars via instance variables" do
      @config.configure do
        @subject_method = :ivar_current_user
      end
      @config.subject_method.should == :ivar_current_user
    end

    it "should allow setting config vars via self" do
      @config.configure do
        self.subject_method = :self_current_user
      end
      @config.subject_method.should == :self_current_user
    end
  end
end
