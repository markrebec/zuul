require 'spec_helper'

describe "Allowables::ActiveRecord::PermissionSubject" do
  before(:each) do
    Permission.acts_as_authorization_permission
  end

  describe "accessible attributes" do
    it "should allow mass assignment of permission class foreign key" do
      pu = PermissionRole.new(:permission_id => 1)
      pu.permission_id.should == 1
    end
    
    it "should allow mass assignment of role class foreign key" do
      pu = PermissionRole.new(:role_id => 1)
      pu.role_id.should == 1
    end
    
    it "should allow mass assignment of :context" do
      context = Context.create(:name => "Test Context")
      pu = PermissionRole.new(:context => context)
      pu.context_type.should == 'Context'
      pu.context_id.should == context.id
    end
    
    it "should allow mass assignment of :context_type" do
      pu = PermissionRole.new(:context_type => 'Context')
      pu.context_type.should == 'Context'
    end
    
    it "should allow mass assignment of :context_id" do
      pu = PermissionRole.new(:context_id => 1)
      pu.context_id.should == 1
    end
  end

  context "validations for core permission fields" do
    it "should validate presence of permission class foreign key" do
      pu = PermissionRole.new()
      pu.valid?.should be_false
      pu.errors.keys.should include(:permission_id)
    end
    
    it "should validate presence of role class foreign key" do
      pu = PermissionRole.new()
      pu.valid?.should be_false
      pu.errors.keys.should include(:role_id)
    end

    it "should validate uniqueness of permission class foreign key scoped to context_type, context_id and the role class foreign key" do
      PermissionRole.create(:permission_id => 1, :role_id => 1)
      pu = PermissionRole.create(:permission_id => 1, :role_id => 1)
      pu.valid?.should be_false
      pu.errors.keys.should include(:permission_id)
      
      PermissionRole.create(:permission_id => 1, :role_id => 1, :context_type => 'Context').valid?.should be_true
      pu = PermissionRole.create(:permission_id => 1, :role_id => 1, :context_type => 'Context')
      pu.valid?.should be_false
      pu.errors.keys.should include(:permission_id)
      
      PermissionRole.create(:permission_id => 1, :role_id => 1, :context_type => 'Context', :context_id => 1).valid?.should be_true
      pu = PermissionRole.create(:permission_id => 1, :role_id => 1, :context_type => 'Context', :context_id => 1)
      pu.valid?.should be_false
      pu.errors.keys.should include(:permission_id)
    end

    it "should validate numericality of permission class foreign key with integers only" do
      pu = PermissionRole.new(:permission_id => 'a', :role_id => 1)
      pu.valid?.should be_false
      pu.errors.keys.should include(:permission_id)
      pu.permission_id = 1.3
      pu.valid?.should be_false
      pu.errors.keys.should include(:permission_id)
    end
  end

  it "should provide the model with has_many associations for permissions and roles" do
    PermissionRole.reflections.keys.should include(:permission)
    PermissionRole.reflections.keys.should include(:role)
    pu = PermissionRole.create(:permission_id => 1, :use_id => 1)
    pu.should respond_to(:permission)
    pu.should respond_to(:role)
  end
end
