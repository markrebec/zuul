require 'spec_helper'

describe "Allowables::ActiveRecord::Permission" do
  context "validations for core permission fields" do
    before(:each) do
      Permission.acts_as_authorization_permission
    end
    
    it "should validate presence of name" do
      permission = Permission.new(:slug => 'edit')
      permission.valid?.should be_false
      permission.errors.keys.should include(:name)
    end

    it "should validate presence of slug" do
      permission = Permission.new(:name => 'Edit')
      permission.valid?.should be_false
      permission.errors.keys.should include(:slug)
    end

    it "should validate format of slug" do
      permission = Permission.new(:name => 'Edit', :slug => 'edit')
      permission.valid?.should be_true
      permission.slug = 'adm in'
      permission.valid?.should be_false
      permission.errors.keys.should include(:slug)
      permission.slug = 'ad*&^;'
      permission.valid?.should be_false
      permission.errors.keys.should include(:slug)
      permission.slug = '{:edit}'
      permission.valid?.should be_false
      permission.errors.keys.should include(:slug)
    end
    
    it "should validate uniqueness of slug scoped to context_type, context_id" do
      Permission.create(:name => 'Edit', :slug => 'edit')
      permission = Permission.new(:name => 'Edit', :slug => 'edit')
      permission.valid?.should be_false
      permission.errors.keys.should include(:slug)
      
      Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context').valid?.should be_true
      permission = Permission.new(:name => 'Edit', :slug => 'edit', :context_type => 'Context')
      permission.valid?.should be_false
      permission.errors.keys.should include(:slug)
      
      Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context', :context_id => 1).valid?.should be_true
      permission = Permission.new(:name => 'Edit', :slug => 'edit', :context_type => 'Context', :context_id => 1)
      permission.valid?.should be_false
      permission.errors.keys.should include(:slug)
    end
  end
  
  it "should provide the model with has_many relationships for permission_subjects and subjects" do
    Permission.acts_as_authorization_permission
    Permission.reflections.keys.should include(:permission_users)
    Permission.reflections.keys.should include(:users)
    permission = Permission.create(:name => 'Edit', :slug => 'edit')
    permission.should respond_to(:permission_users)
    permission.should respond_to(:users)
  end
  
  it "should use the reflection classes to create the has_many relationships" do
    Skill.acts_as_authorization_permission :subject_class => :soldier, :role_class => :rank
    Skill.reflections.keys.should include(:skill_soldiers)
    Skill.reflections.keys.should include(:soldiers)
    skill = Skill.create(:name => 'Marksman', :slug => 'marksman')
    skill.should respond_to(:skill_soldiers)
    skill.should respond_to(:soldiers)
  end
  
  it "should provide the model with has_many relationships for permission_roles and roles" do
    Permission.acts_as_authorization_permission
    Permission.reflections.keys.should include(:permission_roles)
    Permission.reflections.keys.should include(:roles)
    permission = Permission.create(:name => 'Edit', :slug => 'edit')
    permission.should respond_to(:permission_roles)
    permission.should respond_to(:roles)
  end
  
  it "should use the reflection classes to create the has_many relationships" do
    Skill.acts_as_authorization_permission :subject_class => :soldier, :role_class => :rank
    Skill.reflections.keys.should include(:rank_skills)
    Skill.reflections.keys.should include(:ranks)
    skill = Skill.create(:name => 'Marksman', :slug => 'marksman')
    skill.should respond_to(:rank_skills)
    skill.should respond_to(:ranks)
  end
end
