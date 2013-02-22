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

  describe "acts_as_authorization_*" do
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
  
  describe "acts_as_authorization_*?" do
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

  describe "acts_as_authorization_subject" do
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

  describe "acts_as_authorization_role" do
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

  describe "acts_as_authorization_permission" do
    it "should extend the model with Allowables::ActiveRecord::Permission" do
      Permission.acts_as_authorization_permission
      Permission.ancestors.include?(Allowables::ActiveRecord::Permission).should be_true
    end
  end

  describe "acts_as_authorization_context" do
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

    describe "with_permissions methods" do
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

    describe "target_role" do
      pending "should require a role and a context"
      pending "should accept a role object"
      pending "should just return the role object if one is passed"
      pending "should accept a string or symbol"
      
      context "when looking up a role" do
        pending "should use the defined role_class for the lookup"
        pending "should use the provided slug for the lookup"
        
        context "within a context" do
          pending "should go up the context chain to find roles"
          pending "should use the closest contextual match"
        end
      end
    end
    
    describe "target_permission" do
      pending "should require a permission and a context"
      pending "should accept a permission object"
      pending "should just return the permission object if one is passed"
      pending "should accept a string or symbol"
      
      context "when looking up a permission" do
        pending "should use the defined permission_class for the lookup"
        pending "should use the provided slug for the lookup"
        
        context "within a context" do
          pending "should go up the context chain to find permissions"
          pending "should prefer the closest contextual match"
        end
      end
    end

    describe "parse_context" do
      pending "should require a context"
      pending "should allow a class"
      pending "should allow an instance"
      pending "should allow a nil context"
      pending "should return an array with the context broken into it's two parts"
      pending "should return [TheClass, nil] for class context"
      pending "should return [TheClass, id] for an instance context"
      pending "should return [nil, nil] for a nil context"
    end

    describe "verify_target_context" do
      pending "should require a target role or permission and a context"
      pending "should accept a role or a permission as the target"
      pending "should return false if a nil target is provided"
      pending "should allow nil context targets to be used within any other context"
      pending "should allow class context targets to be used within the context of their class or any instances of their class"
      pending "should allow instance targets to be used within their own instance context"
      pending "should not allow class context targets to be used within any other class or nil contexts"
      pending "should not allow instance context targets to be used within any other class or instance contexts or a nil context"
    end
  end

end
