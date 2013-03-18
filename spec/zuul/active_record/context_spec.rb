require 'spec_helper'

describe "Zuul::ActiveRecord::Context" do
  before(:each) do
    User.acts_as_authorization_subject
    Role.acts_as_authorization_role
    Permission.acts_as_authorization_permission
    Context.acts_as_authorization_context
  end

  describe "allowed?" do
    it "should require a subject and a role object or slug" do
      context = Context.create(:name => "Test Context")
      user = User.create(:name => "Test User")
      expect { context.allowed? }.to raise_exception
      expect { context.allowed?(user) }.to raise_exception
    end

    it "should wrap Subect#has_role?" do
      context = Context.create(:name => "Test Context")
      user = User.create(:name => "Test User")
      role = Role.create(:name => "Admin", :slug => "admin", :level => 100)
      context.allowed?(user, role).should be_false
      context.allowed?(user, role).should == user.has_role?(role, context)
      user.assign_role(role, context)
      context.allowed?(user, role).should be_true
      context.allowed?(user, role).should == user.has_role?(role, context)
    end
  end

  describe "allowed_to?" do
    it "should not be available if permissions are disabled" do
      Weapon.acts_as_authorization_context :with_permissions => false
      Weapon.new.should_not respond_to(:allowed_to?)
    end

    it "should require a subject and a permission object or slug" do
      context = Context.create(:name => "Test Context")
      user = User.create(:name => "Test User")
      expect { context.allowed_to? }.to raise_exception
      expect { context.allowed_to?(user) }.to raise_exception
    end

    it "should wrap Subect#has_permission?" do
      context = Context.create(:name => "Test Context")
      user = User.create(:name => "Test User")
      permission = Permission.create(:name => "Edit", :slug => "edit")
      context.allowed_to?(user, permission).should be_false
      context.allowed_to?(user, permission).should == user.has_permission?(permission, context)
      user.assign_permission(permission, context)
      context.allowed_to?(user, permission).should be_true
      context.allowed_to?(user, permission).should == user.has_permission?(permission, context)
    end
  end
end
