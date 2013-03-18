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

    it "should define the :force_context option" do
      Allowables::Configuration::DEFAULT_CONFIGURATION_OPTIONS.has_key?(:force_context).should be_true
      Allowables::Configuration::DEFAULT_CONFIGURATION_OPTIONS[:force_context].should == false
    end
  end

  describe "#configure" do
    context "with a hash" do
      it "should use the hash keys/vals to set instance variables" do
        @config.configure(:subject_class => :custom_subject, :acl_default => :allow)
        @config.subject_class.should == :custom_subject
        @config.acl_default.should == :allow
      end

      it "should not allow setting instance variables that are not defined as defaults" do
        @config.configure(:bad_key => :bad_value)
        @config.should_not respond_to(:bad_key)
        @config.instance_eval do
          @bad_key.should == nil
        end
      end
    end

    context "with a block" do
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

    context "with a hash and a block" do
      it "should use both the hash and block for configuration" do
        @config.configure(:subject_class => :custom_subject) do |config|
          config.role_class = :custom_role
        end
        @config.subject_class.should == :custom_subject
        @config.role_class.should == :custom_role
      end

      it "should override hash values with values set in the block" do
        @config.configure(:role_class => :hash_role) do |config|
          config.role_class = :block_role
        end
        @config.role_class.should == :block_role
      end
    end
    
    it "should redefine the join classes when custom classes are provided" do
      @config.configure(:subject_class => :soldier, :role_class => :rank, :permission_class => :skill)
      @config.role_subject_class.should == "RankSoldier"
      @config.permission_subject_class.should == "SkillSoldier"
      @config.permission_role_class.should == "RankSkill"
    end

    it "should not override join classes if they were provided" do
      @config.configure(:role_subject_class => :special_role_user, :role_class => :rank)
      @config.role_subject_class.should == :special_role_user
    end
  end

  describe "#to_hash" do
    it "should return a hash with all the configuration keys" do
      [Allowables::Configuration::DEFAULT_AUTHORIZATION_CLASSES, Allowables::Configuration::DEFAULT_CONFIGURATION_OPTIONS].each do |opts|
        opts.keys.each do |key|
          @config.to_hash.has_key?(key).should be_true
        end
      end
    end

    it "should populate values with the current configuration values" do
      [Allowables::Configuration::DEFAULT_AUTHORIZATION_CLASSES, Allowables::Configuration::DEFAULT_CONFIGURATION_OPTIONS].each do |opts|
        opts.keys.each do |key|
          @config.to_hash[key].should == @config.send(key)
        end
      end
    end
  end

  describe "#classes" do
    it "should return a ClassStruct" do
      @config.classes.class.ancestors.should include(Allowables::Configuration::ClassStruct)
    end

    it "should return a ClassStruct of all the default configuration classes" do
      Allowables::Configuration::DEFAULT_AUTHORIZATION_CLASSES.keys.each do |key|
        @config.classes.should respond_to(key)
      end
      @config.classes.keys.each do |key|
        Allowables::Configuration::DEFAULT_AUTHORIZATION_CLASSES.has_key?(key).should be_true
      end
    end
  end

  describe "#primary_classes" do
    it "should return a ClassStruct" do
      @config.classes.class.ancestors.should include(Allowables::Configuration::ClassStruct)
    end

    it "should return a ClassStruct of all the default configuration classes" do
      Allowables::Configuration::PRIMARY_AUTHORIZATION_CLASSES.keys.each do |key|
        @config.primary_classes.should respond_to(key)
      end
      @config.primary_classes.keys.each do |key|
        Allowables::Configuration::PRIMARY_AUTHORIZATION_CLASSES.has_key?(key).should be_true
      end
    end
  end

  describe "#join_classes" do
    it "should return a ClassStruct" do
      @config.join_classes.class.ancestors.should include(Allowables::Configuration::ClassStruct)
    end

    it "should return a ClassStruct of all the default configuration join classes" do
      Allowables::Configuration::AUTHORIZATION_JOIN_CLASSES.keys.each do |key|
        @config.join_classes.should respond_to(key)
      end
      @config.join_classes.keys.each do |key|
        Allowables::Configuration::AUTHORIZATION_JOIN_CLASSES.has_key?(key).should be_true
      end
    end
  end

  describe "Allowables::Configuration::ClassStruct" do
    it "should inherit from Struct" do
      Allowables::Configuration::ClassStruct.ancestors.should include(Struct)
    end

    describe "#keys" do
      it "should return an array of keys" do
        Allowables::Configuration::ClassStruct.new(:key1, :key2, :key3).new.keys.should == [:key1, :key2, :key3]
      end
    end

    describe "#to_array" do
      it "should return an array of values" do
        Allowables::Configuration::ClassStruct.new(:key1, :key2, :key3).new(:val1, :val2, :val3).to_array.should == [:val1, :val2, :val3]
      end
    end

    describe "#to_hash" do
      it "should return a hash of key/value pairs" do
        Allowables::Configuration::ClassStruct.new(:key1, :key2, :key3).new(:val1, :val2, :val3).to_hash.should == {:key1 => :val1, :key2 => :val2, :key3 => :val3}
      end
    end
  end
end
