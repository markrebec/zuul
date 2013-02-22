require 'spec_helper'

describe "Allowables::ActiveRecord" do

  it "should extend ActiveRecord::Base with Allowables::ActiveRecord" do
    ActiveRecord::Base.ancestors.include?(Allowables::ActiveRecord).should be_true
  end

  it "should provide the acts_as_authorization_* and acts_as_authorization_*? methods" do
    [:subject, :role, :permission, :context].each do |type|
      ActiveRecord::Base.respond_to?("acts_as_authorization_#{type.to_s}").should be_true
      ActiveRecord::Base.respond_to?("acts_as_authorization_#{type.to_s}?").should be_true
      Dummy.new.respond_to?("acts_as_authorization_#{type.to_s}").should be_false
      Dummy.new.respond_to?("acts_as_authorization_#{type.to_s}?").should be_true 
    end
  end

  context "acts_as_authorization_*" do
    it "should extend the model with Allowables::ActiveRecord::AuthorizationMethods" do
      User.acts_as_authorization_subject
      Role.acts_as_authorization_role
      Permission.acts_as_authorization_permission
      Context.acts_as_authorization_context
      [User, Role, Permission, Context].each do |model|
        model.ancestors.include?(Allowables::ActiveRecord::AuthorizationMethods).should be_true
      end
    end

    # TODO maybe move these into 4 different specs for each method?
    it "should allow passing class arguments to be used with reflections" do
      Soldier.acts_as_authorization_subject :role_class => Rank, :permission_class => Skill
      Rank.acts_as_authorization_role :subject_class => Soldier, :permission_class => Skill
      Skill.acts_as_authorization_permission :subject_class => Soldier, :role_class => Rank
      Weapon.acts_as_authorization_context :permission_class => Skill
    end

    it "should allow class arguments to be provided as classes, strings or symbols" do
      Soldier.acts_as_authorization_subject :role_class => Rank, :permission_class => "Skill"
      Rank.acts_as_authorization_role :subject_class => :soldier, :permission_class => "skill"
      Skill.acts_as_authorization_permission :subject_class => Soldier, :role_class => :Rank
      Weapon.acts_as_authorization_context :permission_class => Skill
    end
  end
  
  context "acts_as_authorization_*?" do
    it "should return false by default" do
      [User, Role, Permission, Context].each do |model|
        [:subject, :role, :permission, :context].each do |type|
          model.send("acts_as_authorization_#{type.to_s}?").should be_false
          model.new.send("acts_as_authorization_#{type.to_s}?").should be_false
        end
      end
    end

    it "should return true if the model acts_as_authorization_*" do
      User.acts_as_authorization_subject
      User.acts_as_authorization_subject?.should be_true
      User.new.acts_as_authorization_subject?.should be_true

      Role.acts_as_authorization_role
      Role.acts_as_authorization_role?.should be_true
      Role.new.acts_as_authorization_role?.should be_true
      
      Permission.acts_as_authorization_permission
      Permission.acts_as_authorization_permission?.should be_true
      Permission.new.acts_as_authorization_permission?.should be_true
      
      Context.acts_as_authorization_context
      Context.acts_as_authorization_context?.should be_true
      Context.new.acts_as_authorization_context?.should be_true
    end
    
    it "should return the same value from instances and their classes" do
      User.acts_as_authorization_subject
      Role.acts_as_authorization_role
      Permission.acts_as_authorization_permission
      Context.acts_as_authorization_context
      [User, Role, Permission, Context].each do |model|
        [:subject, :role, :permission, :context].each do |type|
          model.new.send("acts_as_authorization_#{type.to_s}?").should == model.send("acts_as_authorization_#{type.to_s}?")
        end
      end
    end
  end

  context "acts_as_authorization_subject" do
    it "should extend the model with Allowables::ActiveRecord::Subject" do
      User.acts_as_authorization_subject
      User.ancestors.include?(Allowables::ActiveRecord::Subject).should be_true
    end

    it "should extend the model with Allowables::ActiveRecord::Subject:RoleMethods" do
      User.acts_as_authorization_subject
      User.ancestors.include?(Allowables::ActiveRecord::Subject::RoleMethods).should be_true
    end
    
    it "should extend the model with Allowables::ActiveRecord::Subject:PermissionMethods" do
      User.acts_as_authorization_subject
      User.ancestors.include?(Allowables::ActiveRecord::Subject::PermissionMethods).should be_true
    end
    
    it "should not extend the model with Allowables::ActiveRecord::Subject:PermissionMethods if :with_permissions => false" do
      User.acts_as_authorization_subject :with_permissions => false
      User.ancestors.include?(Allowables::ActiveRecord::Subject::PermissionMethods).should be_false
    end
  end

  context "acts_as_authorization_role" do
    it "should extend the model with Allowables::ActiveRecord::Role" do
      Role.acts_as_authorization_role
      Role.ancestors.include?(Allowables::ActiveRecord::Role).should be_true
    end
    
    it "should extend the model with Allowables::ActiveRecord::Role::InstanceMethods" do
      Role.acts_as_authorization_role
      Role.ancestors.include?(Allowables::ActiveRecord::Role::InstanceMethods).should be_true
    end
    
    it "should not extend the model with Allowables::ActiveRecord::Role::InstanceMethods if :with_permissions => false" do
      Role.acts_as_authorization_role :with_permissions => false
      Role.ancestors.include?(Allowables::ActiveRecord::Role::InstanceMethods).should be_false
    end
  end

  context "acts_as_authorization_permission" do
    it "should extend the model with Allowables::ActiveRecord::Permission" do
      Permission.acts_as_authorization_permission
      Permission.ancestors.include?(Allowables::ActiveRecord::Permission).should be_true
    end
  end

  context "acts_as_authorization_context" do
    it "should extend the model with Allowables::ActiveRecord::Context" do
      Context.acts_as_authorization_context
      Context.ancestors.include?(Allowables::ActiveRecord::Context).should be_true
    end
  end

  describe "AuthorizationMethods" do
    it "should extend the model with Allowables::ActiveRecord::Reflection" do
      Dummy.send :include, Allowables::ActiveRecord
      Dummy.send :include, Allowables::ActiveRecord::AuthorizationMethods
      Dummy.ancestors.include?(Allowables::ActiveRecord::Reflection).should be_true
    end

    context "with_permissions methods" do
      it "should be available to models that acts_as_authorization_*" do
        User.acts_as_authorization_subject
        Role.acts_as_authorization_role
        Permission.acts_as_authorization_permission
        Context.acts_as_authorization_context
        [User, Role, Permission, Context].each do |model|
          model.respond_to?(:with_permissions).should be_true
          model.respond_to?(:with_permissions?).should be_true
          model.new.respond_to?(:with_permissions).should be_true
          model.new.respond_to?(:with_permissions?).should be_true
        end
      end

      it "should allow setting the with_permissions flag with the setter" do
        Dummy.send :include, Allowables::ActiveRecord
        Dummy.send :include, Allowables::ActiveRecord::AuthorizationMethods
        Dummy.send(:instance_variable_get, :@with_permissions).should be_nil
        Dummy.with_permissions(false)
        Dummy.send(:instance_variable_get, :@with_permissions).should be_false
      end

      it "should allow reading the with_permissions flag with the query method" do
        Dummy.send :include, Allowables::ActiveRecord
        Dummy.send :include, Allowables::ActiveRecord::AuthorizationMethods
        Dummy.with_permissions?.should be_true
        Dummy.with_permissions(false)
        Dummy.with_permissions?.should be_false
      end

      it "should default to true" do
        Dummy.send :include, Allowables::ActiveRecord
        Dummy.send :include, Allowables::ActiveRecord::AuthorizationMethods
        Dummy.send(:instance_variable_get, :@with_permissions).should be_nil
        Dummy.with_permissions?.should be_true
      end

      it "should return the same value from an instance and it's class" do
        User.acts_as_authorization_subject :with_permissions => false
        Role.acts_as_authorization_role
        Context.acts_as_authorization_context :with_permissions => false
        [User, Role, Context].each do |model|
          model.with_permissions?.should == model.new.with_permissions?
        end
      end
    end

    context "target_role" do
    end
    
    context "target_permission" do
    end

    context "parse_context" do
    end

    context "verify_target_context" do
    end
  end

end
