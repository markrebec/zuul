require 'spec_helper'

describe "Zuul::ActiveRecord::PermissionSubject" do
  before(:each) do
    Permission.acts_as_authorization_permission
  end

  describe "accessible attributes" do
    it "should allow mass assignment of permission class foreign key" do
      pu = PermissionUser.new(:permission_id => 1)
      pu.permission_id.should == 1
    end
    
    it "should allow mass assignment of subject class foreign key" do
      pu = PermissionUser.new(:user_id => 1)
      pu.user_id.should == 1
    end
    
    it "should allow mass assignment of :context" do
      context = Context.create(:name => "Test Context")
      pu = PermissionUser.new(:context => context)
      pu.context_type.should == 'Context'
      pu.context_id.should == context.id
    end
    
    it "should allow mass assignment of :context_type" do
      pu = PermissionUser.new(:context_type => 'Context')
      pu.context_type.should == 'Context'
    end
    
    it "should allow mass assignment of :context_id" do
      pu = PermissionUser.new(:context_id => 1)
      pu.context_id.should == 1
    end
  end

  context "validations for core permission fields" do
    it "should validate presence of permission class foreign key" do
      pu = PermissionUser.new()
      pu.valid?.should be_false
      pu.errors.keys.should include(:permission_id)
    end
    
    it "should validate presence of subject class foreign key" do
      pu = PermissionUser.new()
      pu.valid?.should be_false
      pu.errors.keys.should include(:user_id)
    end

    it "should validate uniqueness of permission class foreign key scoped to context_type, context_id and the subject class foreign key" do
      PermissionUser.create(:permission_id => 1, :user_id => 1)
      pu = PermissionUser.create(:permission_id => 1, :user_id => 1)
      pu.valid?.should be_false
      pu.errors.keys.should include(:permission_id)
      
      PermissionUser.create(:permission_id => 1, :user_id => 1, :context_type => 'Context').valid?.should be_true
      pu = PermissionUser.create(:permission_id => 1, :user_id => 1, :context_type => 'Context')
      pu.valid?.should be_false
      pu.errors.keys.should include(:permission_id)
      
      PermissionUser.create(:permission_id => 1, :user_id => 1, :context_type => 'Context', :context_id => 1).valid?.should be_true
      pu = PermissionUser.create(:permission_id => 1, :user_id => 1, :context_type => 'Context', :context_id => 1)
      pu.valid?.should be_false
      pu.errors.keys.should include(:permission_id)
    end

    it "should validate numericality of permission class foreign key with integers only" do
      pu = PermissionUser.new(:permission_id => 'a', :user_id => 1)
      pu.valid?.should be_false
      pu.errors.keys.should include(:permission_id)
      pu.permission_id = 1.3
      pu.valid?.should be_false
      pu.errors.keys.should include(:permission_id)
    end
  end

  it "should provide the model with belongs_to associations for permissions and subjects" do
    PermissionUser.reflections.keys.should include(:permission)
    PermissionUser.reflections.keys.should include(:user)
    pu = PermissionUser.create(:permission_id => 1, :use_id => 1)
    pu.should respond_to(:permission)
    pu.should respond_to(:user)
  end
end
