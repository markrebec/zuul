require 'spec_helper'

describe "Allowables::ActiveRecord::RoleSubject" do
  before(:each) do
    Role.acts_as_authorization_role
  end

  describe "accessible attributes" do
    it "should allow mass assignment of role class foreign key" do
      ru = RoleUser.new(:role_id => 1)
      ru.role_id.should == 1
    end
    
    it "should allow mass assignment of subject class foreign key" do
      ru = RoleUser.new(:user_id => 1)
      ru.user_id.should == 1
    end
    
    it "should allow mass assignment of :context" do
      context = Context.create(:name => "Test Context")
      ru = RoleUser.new(:context => context)
      ru.context_type.should == 'Context'
      ru.context_id.should == context.id
    end
    
    it "should allow mass assignment of :context_type" do
      ru = RoleUser.new(:context_type => 'Context')
      ru.context_type.should == 'Context'
    end
    
    it "should allow mass assignment of :context_id" do
      ru = RoleUser.new(:context_id => 1)
      ru.context_id.should == 1
    end
  end

  context "validations for core role fields" do
    it "should validate presence of role class foreign key" do
      ru = RoleUser.new()
      ru.valid?.should be_false
      ru.errors.keys.should include(:role_id)
    end
    
    it "should validate presence of subject class foreign key" do
      ru = RoleUser.new()
      ru.valid?.should be_false
      ru.errors.keys.should include(:user_id)
    end

    it "should validate uniqueness of role class foreign key scoped to context_type, context_id and the subject class foreign key" do
      RoleUser.create(:role_id => 1, :user_id => 1)
      ru = RoleUser.create(:role_id => 1, :user_id => 1)
      ru.valid?.should be_false
      ru.errors.keys.should include(:role_id)
      
      RoleUser.create(:role_id => 1, :user_id => 1, :context_type => 'Context').valid?.should be_true
      ru = RoleUser.create(:role_id => 1, :user_id => 1, :context_type => 'Context')
      ru.valid?.should be_false
      ru.errors.keys.should include(:role_id)
      
      RoleUser.create(:role_id => 1, :user_id => 1, :context_type => 'Context', :context_id => 1).valid?.should be_true
      ru = RoleUser.create(:role_id => 1, :user_id => 1, :context_type => 'Context', :context_id => 1)
      ru.valid?.should be_false
      ru.errors.keys.should include(:role_id)
    end

    it "should validate numericality of role class foreign key with integers only" do
      ru = RoleUser.new(:role_id => 'a', :user_id => 1)
      ru.valid?.should be_false
      ru.errors.keys.should include(:role_id)
      ru.role_id = 1.3
      ru.valid?.should be_false
      ru.errors.keys.should include(:role_id)
    end
  end

  it "should provide the model with has_many associations for roles and subjects" do
    RoleUser.reflections.keys.should include(:role)
    RoleUser.reflections.keys.should include(:user)
    ru = RoleUser.create(:role_id => 1, :use_id => 1)
    ru.should respond_to(:role)
    ru.should respond_to(:user)
  end
end
