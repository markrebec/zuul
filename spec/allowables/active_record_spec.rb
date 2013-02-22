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

    pending "needs more cowbell"
  end

  context "acts_as_authorization_role" do
    it "should extend the model with Allowables::ActiveRecord::Role" do
      Role.acts_as_authorization_role
      Role.ancestors.include?(Allowables::ActiveRecord::Role).should be_true
    end

    pending "needs more cowbell"
  end

  context "acts_as_authorization_permission" do
    it "should extend the model with Allowables::ActiveRecord::Permission" do
      Permission.acts_as_authorization_permission
      Permission.ancestors.include?(Allowables::ActiveRecord::Permission).should be_true
    end

    pending "needs more cowbell"
  end

  context "acts_as_authorization_context" do
    it "should extend the model with Allowables::ActiveRecord::Context" do
      Context.acts_as_authorization_context
      Context.ancestors.include?(Allowables::ActiveRecord::Context).should be_true
    end

    pending "needs more cowbell"
  end

  describe "AuthorizationMethods" do
    it "should extend the model with Allowables::ActiveRecord::Reflection" do
      User.acts_as_authorization_subject
      Role.acts_as_authorization_role
      Permission.acts_as_authorization_permission
      Context.acts_as_authorization_context
      [User, Role, Permission, Context].each do |model|
        model.ancestors.include?(Allowables::ActiveRecord::Reflection).should be_true
      end
    end
  end

end
