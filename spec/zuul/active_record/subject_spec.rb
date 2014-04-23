require 'spec_helper'

describe "Zuul::ActiveRecord::Subject" do
  it "should extend the model with RoleMethods" do
    User.acts_as_authorization_subject
    User.ancestors.include?(Zuul::ActiveRecord::Subject::RoleMethods).should == true
  end

  it "should extend the model with PermissionMethods if permissions are enabled" do
    User.acts_as_authorization_subject
    User.ancestors.include?(Zuul::ActiveRecord::Subject::PermissionMethods).should == true
  end

  it "should not extend the model with PermissionMethods if permissions are disabled" do
    User.acts_as_authorization_subject :with_permissions => false
    User.ancestors.include?(Zuul::ActiveRecord::Subject::PermissionMethods).should be_false
  end

  describe "RoleMethods" do
    before(:each) do
      User.acts_as_authorization_subject
      Role.acts_as_authorization_role
    end

    it "should provide the model with has_many associations for role_subjects and roles" do
      user = User.create(:name => "Test User")
      User.reflections.keys.should include(:role_users)
      User.reflections.keys.should include(:roles)
      user.should respond_to(:role_users)
      user.should respond_to(:roles)
    end
  
    it "should use :dependent => :destroy for the role_subjects association" do
      user = User.create(:name => 'Tester')
      role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
      user.assign_role(:admin)
      RoleUser.count.should == 1
      user.destroy
      RoleUser.count.should == 0
    end

    it "should use the reflection classes to create the has_many associations" do
      Soldier.acts_as_authorization_subject :role_class => :rank, :with_permissions => false
      Rank.acts_as_authorization_role :subject_class => :soldier, :with_permissions => false
      soldier = Soldier.create(:name => "Test User")
      Soldier.reflections.keys.should include(:rank_soldiers)
      Soldier.reflections.keys.should include(:ranks)
      soldier.should respond_to(:rank_soldiers)
      soldier.should respond_to(:ranks)
    end
    
    describe "assign_role" do
      before(:each) do
        @user = User.create(:name => "Test User")
      end
      
      it "should require a role object or slug" do
        expect { @user.assign_role }.to raise_exception
      end

      it "should accept an optional context" do
        role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        expect { @user.assign_role(:admin, nil) }.to_not raise_exception
      end

      it "should use nil context when none is provided" do
        role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        role_user = @user.assign_role(:admin)
        role_user.id.should_not be_nil
        role_user.context_type.should be_nil
      end

      it "should use the context when one is provided" do
        role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        context = Context.create(:name => "Test Context")
        
        class_role_user = @user.assign_role(role, Context)
        class_role_user.id.should_not be_nil
        class_role_user.context_type.should == 'Context'
        class_role_user.context_id.should be_nil
        
        inst_role_user = @user.assign_role(role, context)
        inst_role_user.id.should_not be_nil
        inst_role_user.context_type.should == 'Context'
        inst_role_user.context_id.should == context.id
      end

      it "should use target_role to lookup the closest contextual match when a role slug is provided" do
        context = Context.create(:name => "Test Context")
        nil_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        class_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context')
        inst_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context', :context_id => context.id)
        
        nil_role_user = @user.assign_role(:admin, nil)
        nil_role_user.id.should_not be_nil
        nil_role_user.context_type.should be_nil
        nil_role_user.context_id.should be_nil
        nil_role_user.role.id.should == nil_role.id
        
        class_role_user = @user.assign_role(:admin, Context)
        class_role_user.id.should_not be_nil
        class_role_user.context_type.should == 'Context'
        class_role_user.context_id.should be_nil
        class_role_user.role.id.should == class_role.id
        
        inst_role_user = @user.assign_role(:admin, context)
        inst_role_user.id.should_not be_nil
        inst_role_user.context_type.should == 'Context'
        inst_role_user.context_id.should == context.id
        inst_role_user.role.id.should == inst_role.id
      end

      it "should use the role object when one is provided" do
        context = Context.create(:name => "Test Context")
        nil_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        class_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context')
        inst_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context', :context_id => context.id)
        
        class_role_user = @user.assign_role(nil_role, Context)
        class_role_user.id.should_not be_nil
        class_role_user.context_type.should == 'Context'
        class_role_user.context_id.should be_nil
        class_role_user.role.id.should == nil_role.id
        
        inst_role_user = @user.assign_role(nil_role, context)
        inst_role_user.id.should_not be_nil
        inst_role_user.context_type.should == 'Context'
        inst_role_user.context_id.should == context.id
        inst_role_user.role.id.should == nil_role.id
      end

      it "should fail and return false if the provided role is nil" do
        @user.assign_role(nil).should be_false
        @user.assign_role(nil, Context).should be_false
      end

      it "should fail and return false if the provided role cannot be used within the provided context" do
        context = Context.create(:name => "Test Context")
        class_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context')
        inst_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context', :context_id => context.id)

        @user.assign_role(class_role, nil).should be_false
        @user.assign_role(inst_role, nil).should be_false
        @user.assign_role(inst_role, Context).should be_false
      end

      it "should create the role_subjects record to link the subject to the provided role" do
        role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        @user.assign_role(role)
        RoleUser.where(:user_id => @user.id, :role_id => role.id).count.should == 1
      end

      it "should return the assigned role if it is already assigned within the provided context" do
        role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        context = Context.create(:name => "Test Context")
        @user.assign_role(role)
        @user.assign_role(role).should be_an_instance_of(RoleUser)
        RoleUser.where(:user_id => @user.id, :role_id => role.id, :context_type => nil, :context_id => nil).count.should == 1
        @user.assign_role(role, Context)
        @user.assign_role(role, Context).should be_an_instance_of(RoleUser)
        RoleUser.where(:user_id => @user.id, :role_id => role.id, :context_type => 'Context', :context_id => nil).count.should == 1
        @user.assign_role(role, context)
        @user.assign_role(role, context).should be_an_instance_of(RoleUser)
        RoleUser.where(:user_id => @user.id, :role_id => role.id, :context_type => 'Context', :context_id => context.id).count.should == 1
      end

      context "when forcing context" do
        it "should not go up the context chain to find the role when a role slug is provided" do
          context = Context.create(:name => "Test Context")
          
          nil_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
          nil_role_user = @user.assign_role(:admin, nil, true)
          nil_role_user.id.should_not be_nil
          nil_role_user.context_type.should be_nil
          nil_role_user.context_id.should be_nil
          nil_role_user.role.id.should == nil_role.id
          
          @user.assign_role(:admin, Context, true).should be_false
          class_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context')
          class_role_user = @user.assign_role(:admin, Context, true)
          class_role_user.id.should_not be_nil
          class_role_user.context_type.should == 'Context'
          class_role_user.context_id.should be_nil
          class_role_user.role.id.should == class_role.id
          
          @user.assign_role(:admin, context, true).should be_false
          inst_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context', :context_id => context.id)
          inst_role_user = @user.assign_role(:admin, context, true)
          inst_role_user.id.should_not be_nil
          inst_role_user.context_type.should == 'Context'
          inst_role_user.context_id.should == context.id
          inst_role_user.role.id.should == inst_role.id
        end
      end
    end

    describe "unassign_role" do
      before(:each) do
        @user = User.create(:name => "Test User")
      end
      
      it "should require a role object or slug" do
        expect { @user.unassign_role }.to raise_exception
      end

      it "should accept an optional context" do
        role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        expect { @user.unassign_role(:admin, nil) }.to_not raise_exception
      end

      it "should use nil context when none is provided" do
        role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        @user.assign_role(:admin, nil)
        @user.assign_role(:admin, Context)

        unassigned = @user.unassign_role(:admin)
        unassigned.should be_an_instance_of(RoleUser)
        roles = RoleUser.where(:user_id => @user.id, :role_id => role.id)
        roles.length.should == 1
        roles[0].context_type.should == 'Context'
      end

      it "should use target_role to lookup the closest contextual match when a role slug is provided" do
        context = Context.create(:name => "Test Context")
        nil_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        class_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context')
        inst_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context', :context_id => context.id)
        @user.assign_role(nil_role, nil)
        @user.assign_role(class_role, Context)
        @user.assign_role(nil_role, Context)
        @user.assign_role(inst_role, context)
        @user.assign_role(class_role, context)
        
        @user.unassign_role(:admin, context).role_id.should == inst_role.id
        @user.unassign_role(:admin, context).should be_false
        @user.unassign_role(:admin, Context).role_id.should == class_role.id
        @user.unassign_role(:admin, Context).should be_false
      end

      it "should use the role object when one is provided" do
        context = Context.create(:name => "Test Context")
        nil_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        class_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context')
        inst_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context', :context_id => context.id)
        @user.assign_role(nil_role, nil)
        @user.assign_role(class_role, Context)
        @user.assign_role(nil_role, Context)
        @user.assign_role(inst_role, context)
        @user.assign_role(class_role, context)
        
        @user.unassign_role(class_role, context).role_id.should == class_role.id
        @user.unassign_role(inst_role, context).role_id.should == inst_role.id
        @user.unassign_role(nil_role, Context).role_id.should == nil_role.id
        @user.unassign_role(class_role, Context).role_id.should == class_role.id
      end

      it "should fail and return false if the provided role is nil" do
        @user.unassign_role(nil).should be_false
        @user.unassign_role(nil, Context).should be_false
      end

      it "should remove the role_subjects record that links the subject to the provided role" do
        role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        @user.assign_role(role)
        RoleUser.where(:user_id => @user.id, :role_id => role.id).count.should == 1
        @user.unassign_role(role)
        RoleUser.where(:user_id => @user.id, :role_id => role.id).count.should == 0
      end

      it "should fail and return false if the provided role is not assigned in the provided context" do
        context = Context.create(:name => "Test Context")
        nil_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        class_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context')
        inst_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context', :context_id => context.id)
        @user.assign_role(nil_role, Context)
        @user.assign_role(class_role, context)
        
        @user.unassign_role(inst_role, context).should be_false
        @user.unassign_role(nil_role, nil).should be_false
        @user.unassign_role(class_role, Context).should be_false
      end
      
      context "when forcing context" do
        it "should not go up the context chain to find the role when a role slug is provided" do
          context = Context.create(:name => "Test Context")
          nil_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
          class_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context')
          inst_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context', :context_id => context.id)
          @user.assign_role(nil_role, nil)
          @user.assign_role(class_role, Context)
          @user.assign_role(nil_role, Context)
          @user.assign_role(inst_role, context)
          @user.assign_role(class_role, context)
          
          @user.unassign_role(:admin, context, true).role_id.should == inst_role.id
          inst_role.destroy
          @user.unassign_role(:admin, context, true).should be_false
          @user.unassign_role(:admin, Context, true).role_id.should == class_role.id
          class_role.destroy
          @user.unassign_role(:admin, Context, true).should be_false
        end
      end
    end

    describe "has_role?" do
      before(:each) do
        @user = User.create(:name => "Test User")
      end
      
      it "should require a role object or slug" do
        expect { @user.has_role? }.to raise_exception
      end

      it "should accept an optional context" do
        role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        expect { @user.has_role?(:admin, nil) }.to_not raise_exception
      end

      it "should use nil context when none is provided" do
        role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        @user.assign_role(:admin, Context)
        @user.has_role?(:admin).should be_false
        @user.assign_role(:admin, nil)
        @user.has_role?(:admin).should be_true
      end

      it "should use target_role to lookup the closest contextual match when a role slug is provided" do
        context = Context.create(:name => "Test Context")
        nil_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        class_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context')
        inst_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context', :context_id => context.id)
        @user.assign_role(nil_role, Context)
        @user.assign_role(class_role, context)
        
        @user.has_role?(:admin, Context).should be_false
        @user.has_role?(:admin, context).should be_false
        
        @user.assign_role(class_role, Context)
        @user.assign_role(inst_role, context)
        
        @user.has_role?(:admin, Context).should be_true
        @user.has_role?(:admin, context).should be_true
      end

      it "should use the role object when one is provided" do
        context = Context.create(:name => "Test Context")
        nil_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        class_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context')
        inst_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context', :context_id => context.id)
        @user.assign_role(nil_role, Context)
        @user.assign_role(class_role, context)
        
        @user.has_role?(nil_role, Context).should be_true
        @user.has_role?(class_role, context).should be_true
        @user.has_role?(class_role, Context).should be_false
        @user.has_role?(inst_role, context).should be_false
        
        @user.assign_role(class_role, Context)
        @user.assign_role(inst_role, context)
        
        @user.has_role?(class_role, Context).should be_true
        @user.has_role?(inst_role, context).should be_true
      end

      it "should return false if the provided role is nil" do
        @user.has_role?(nil).should be_false
        @user.has_role?(nil, Context).should be_false
      end

      it "should look up the context chain for the assigned role" do
        context = Context.create(:name => "Test Context")
        role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        @user.assign_role(role, nil)
        @user.has_role?(:admin, Context).should be_true
        @user.has_role?(:admin, context).should be_true
        @user.unassign_role(role, nil)
        @user.assign_role(role, Context)
        @user.has_role?(:admin, context).should be_true
      end

      it "should return false if the provided role is not assigned to the subject within the context chain" do
        context = Context.create(:name => "Test Context")
        role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        @user.has_role?(role, context).should be_false
        @user.has_role?(:admin, Context).should be_false
        @user.has_role?(role, nil).should be_false
        
        @user.assign_role(:admin, context)
        @user.has_role?(:admin, context).should_not be_false
        @user.has_role?(role, Context).should be_false
        @user.has_role?(:admin, nil).should be_false
        
        @user.assign_role(:admin, Context)
        @user.has_role?(:admin, context).should_not be_false
        @user.has_role?(role, Context).should_not be_false
        @user.has_role?(role, nil).should be_false
      end
      
      context "when forcing context" do
        it "should not go up the context chain to find the role when a role slug is provided" do
          context = Context.create(:name => "Test Context")
          nil_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
          @user.assign_role(nil_role, Context)
          @user.has_role?(:admin, Context, false).should be_true
          @user.has_role?(:admin, Context, true).should be_false
          
          class_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context')
          @user.assign_role(class_role, context)
          @user.has_role?(:admin, context, false).should be_true
          @user.has_role?(:admin, context, true).should be_false
        end
      end
    end

    describe "has_role_or_higher?" do
      before(:each) do
        @user = User.create(:name => "Test User")
      end
      
      it "should require a role object or slug" do
        expect { @user.has_role_or_higher? }.to raise_exception
      end

      it "should accept an optional context" do
        role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        expect { @user.has_role_or_higher?(:admin, nil) }.to_not raise_exception
      end

      it "should use nil context when none is provided" do
        admin_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        mod_role = Role.create(:name => 'Moderator', :slug => 'moderator', :level => 80)
        @user.assign_role(:admin, Context)
        @user.has_role_or_higher?(:admin).should be_false
        @user.has_role_or_higher?(:moderator).should be_false
        @user.assign_role(:admin, nil)
        @user.has_role_or_higher?(:admin).should be_true
        @user.has_role_or_higher?(:moderator).should be_true
      end

      it "should use target_role to lookup the closest contextual match when a role slug is provided" do
        context = Context.create(:name => "Test Context")
        nil_admin = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        class_admin = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context')
        inst_admin = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context', :context_id => context.id)
        nil_mod = Role.create(:name => 'Moderator', :slug => 'moderator', :level => 80)
        class_mod = Role.create(:name => 'Moderator', :slug => 'moderator', :level => 80, :context_type => 'Context')
        inst_mod = Role.create(:name => 'Moderator', :slug => 'moderator', :level => 80, :context_type => 'Context', :context_id => context.id)
        @user.assign_role(nil_admin, Context)
        @user.assign_role(class_admin, context)
        
        @user.has_role_or_higher?(:admin, Context).should be_false
        @user.has_role_or_higher?(:moderator, Context).should be_false
        @user.has_role_or_higher?(:admin, context).should be_false
        @user.has_role_or_higher?(:moderator, context).should be_false
        
        @user.assign_role(class_admin, Context)
        @user.assign_role(inst_admin, context)
        
        @user.has_role_or_higher?(:admin, Context).should be_true
        @user.has_role_or_higher?(:moderator, Context).should be_true
        @user.has_role_or_higher?(:admin, context).should be_true
        @user.has_role_or_higher?(:moderator, context).should be_true
      end

      it "should use the role object when one is provided" do
        context = Context.create(:name => "Test Context")
        nil_admin = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        class_admin = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context')
        inst_admin = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context', :context_id => context.id)
        nil_mod = Role.create(:name => 'Moderator', :slug => 'moderator', :level => 80)
        class_mod = Role.create(:name => 'Moderator', :slug => 'moderator', :level => 80, :context_type => 'Context')
        inst_mod = Role.create(:name => 'Moderator', :slug => 'moderator', :level => 80, :context_type => 'Context', :context_id => context.id)
        @user.assign_role(nil_admin, Context)
        @user.assign_role(class_admin, context)
        
        @user.has_role_or_higher?(nil_admin, Context).should be_true
        @user.has_role_or_higher?(nil_mod, Context).should be_true
        @user.has_role_or_higher?(class_admin, context).should be_true
        @user.has_role_or_higher?(class_mod, context).should be_true
        @user.has_role_or_higher?(class_admin, Context).should be_false
        @user.has_role_or_higher?(class_mod, Context).should be_false
        @user.has_role_or_higher?(inst_admin, context).should be_false
        @user.has_role_or_higher?(inst_mod, context).should be_false
        
        @user.assign_role(class_admin, Context)
        @user.assign_role(inst_admin, context)
        
        @user.has_role_or_higher?(class_admin, Context).should be_true
        @user.has_role_or_higher?(class_mod, Context).should be_true
        @user.has_role_or_higher?(inst_admin, context).should be_true
        @user.has_role_or_higher?(inst_mod, context).should be_true
      end

      it "should return false if the provided role is nil" do
        @user.has_role_or_higher?(nil).should be_false
        @user.has_role_or_higher?(nil, Context).should be_false
      end

      it "should return true if the subject has the provided role via has_role?" do
        context = Context.create(:name => "Test Context")
        admin_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        mod_role = Role.create(:name => 'Moderator', :slug => 'moderator', :level => 80)
        @user.assign_role(admin_role, nil)
        @user.has_role_or_higher?(:admin, nil).should be_true
      end

      it "should look up the context chain for an assigned role with a level >= that of the provided role" do
        context = Context.create(:name => "Test Context")
        admin_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        mod_role = Role.create(:name => 'Moderator', :slug => 'moderator', :level => 80)
        @user.assign_role(admin_role, nil)
        @user.has_role_or_higher?(:admin, Context).should be_true
        @user.has_role_or_higher?(:moderator, Context).should be_true
        @user.has_role_or_higher?(:admin, context).should be_true
        @user.has_role_or_higher?(:moderator, context).should be_true
        @user.unassign_role(admin_role, nil)
        @user.assign_role(admin_role, Context)
        @user.has_role_or_higher?(:admin, context).should be_true
        @user.has_role_or_higher?(:moderator, context).should be_true
      end

      it "should return false if a role with a level >= that of the provided role is not assigned to the subject within the context chain" do
        context = Context.create(:name => "Test Context")
        admin_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        mod_role = Role.create(:name => 'Moderator', :slug => 'moderator', :level => 80)
        @user.has_role_or_higher?(admin_role, context).should be_false
        @user.has_role_or_higher?(admin_role, context).should be_false
        @user.has_role_or_higher?(:admin, Context).should be_false
        @user.has_role_or_higher?(:moderator, Context).should be_false
        @user.has_role_or_higher?(admin_role, nil).should be_false
        @user.has_role_or_higher?(mod_role, nil).should be_false
        
        @user.assign_role(:admin, context)
        @user.has_role_or_higher?(:admin, context).should_not be_false
        @user.has_role_or_higher?(:moderator, context).should_not be_false
        @user.has_role_or_higher?(admin_role, Context).should be_false
        @user.has_role_or_higher?(mod_role, Context).should be_false
        @user.has_role_or_higher?(:admin, nil).should be_false
        @user.has_role_or_higher?(:moderator, nil).should be_false
        
        @user.assign_role(:admin, Context)
        @user.has_role_or_higher?(:admin, context).should_not be_false
        @user.has_role_or_higher?(:moderator, context).should_not be_false
        @user.has_role_or_higher?(admin_role, Context).should_not be_false
        @user.has_role_or_higher?(mod_role, Context).should_not be_false
        @user.has_role_or_higher?(admin_role, nil).should be_false
        @user.has_role_or_higher?(mod_role, nil).should be_false
      end
      
      context "when forcing context" do
        it "should not go up the context chain to find the role when a role slug is provided" do
          context = Context.create(:name => "Test Context")
          nil_admin = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
          nil_mod = Role.create(:name => 'Moderator', :slug => 'moderator', :level => 80)
          @user.assign_role(nil_admin, Context)
          @user.has_role_or_higher?(:admin, Context, false).should be_true
          @user.has_role_or_higher?(:admin, Context, true).should be_false
          @user.has_role_or_higher?(:moderator, Context, false).should be_true
          @user.has_role_or_higher?(:moderator, Context, true).should be_false
          
          class_admin = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context')
          class_mod = Role.create(:name => 'Moderator', :slug => 'moderator', :level => 80, :context_type => 'Context')
          @user.assign_role(class_admin, context)
          @user.has_role_or_higher?(:admin, context, false).should be_true
          @user.has_role_or_higher?(:admin, context, true).should be_false
          @user.has_role_or_higher?(:moderator, context, false).should be_true
          @user.has_role_or_higher?(:moderator, context, true).should be_false
        end
      end
    end

    describe "highest_role" do
      before(:each) do
        @user = User.create(:name => "Test User")
      end
      
      it "should accept an optional context" do
        expect { @user.highest_role(nil) }.to_not raise_exception
      end

      it "should use nil context when none is provided" do
        admin_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        @user.assign_role(admin_role, nil)
        @user.highest_role.id.should == admin_role.id
      end

      it "should return nil if no roles are assigned to the subject within the provided context" do
        admin_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        @user.highest_role(nil).should be_nil
        @user.highest_role(Context).should be_nil
        
        @user.assign_role(admin_role, nil)
        
        @user.highest_role(nil).id.should == admin_role.id
        @user.highest_role(Context).id.should == admin_role.id
      end

      it "should return the role with the highest level that is assigned to the subject within the provided context" do
        admin_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        mod_role = Role.create(:name => 'Moderator', :slug => 'moderator', :level => 80)
        @user.assign_role(admin_role, nil)
        @user.assign_role(mod_role, nil)
        @user.assign_role(mod_role, Context)
        @user.highest_role(nil).id.should == admin_role.id
        @user.highest_role(Context).id.should == admin_role.id
        @user.assign_role(admin_role, Context)
        @user.highest_role(Context).id.should == admin_role.id
      end
      
      context "when forcing context" do
        it "should only evaluate roles that match the context exactly" do
          admin_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
          mod_role = Role.create(:name => 'Moderator', :slug => 'moderator', :level => 80)
          @user.assign_role(admin_role, nil)
          @user.assign_role(mod_role, nil)
          @user.highest_role(nil).id.should == admin_role.id
          @user.highest_role(Context).id.should == admin_role.id
          @user.highest_role(Context, true).should be_nil
        end
      end
    end

    describe "roles_for" do
      before(:each) do
        @user = User.create(:name => "Test User")
      end
      
      it "should accept an optional context" do
        expect { @user.roles_for(nil) }.to_not raise_exception
      end
      
      it "should use nil context when none is provided" do
        admin_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        @user.assign_role(admin_role, Context)
        @user.roles_for.length.should == 0
        @user.assign_role(admin_role, nil)
        @user.roles_for.length.should == 1
      end

      it "should return an empty association array if no roles are assigned to the subject within the provided context" do
        context = Context.create(:name => "Test Context")
        role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        @user.assign_role(role, context)
        @user.roles_for(nil).length.should == 0
        @user.roles_for(Context).length.should == 0
      end

      it "should return all roles assigned to the subject within the provided context" do
        nil_admin = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        class_admin = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context')
        class_mod = Role.create(:name => 'Moderator', :slug => 'moderator', :level => 80, :context_type => 'Context')
        @user.assign_role(nil_admin, Context)
        @user.assign_role(class_admin, Context)
        @user.assign_role(class_mod, Context)
        @user.roles_for(Context).length.should == 3
      end
      
      context "when forcing context" do
        it "should only return roles that match the context exactly" do
          admin_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
          mod_role = Role.create(:name => 'Moderator', :slug => 'moderator', :level => 80)
          @user.assign_role(admin_role, nil)
          @user.assign_role(mod_role, nil)
          @user.roles_for(nil).length.should == 2
          @user.roles_for(Context).length.should == 2
          @user.roles_for(Context, true).length.should == 0
        end
      end
    end

    describe "roles_for?" do
      before(:each) do
        @user = User.create(:name => "Test User")
      end
      
      it "should accept an optional context" do
        expect { @user.roles_for?(nil) }.to_not raise_exception
      end
      
      it "should use nil context when none is provided" do
        admin_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        @user.assign_role(admin_role, Context)
        @user.roles_for?.should be_false
        @user.assign_role(admin_role, nil)
        @user.roles_for?.should be_true
      end

      it "should return false if no roles are assigned to the subject within the provided context" do
        context = Context.create(:name => "Test Context")
        role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        @user.assign_role(role, context)
        @user.roles_for?(nil).should be_false
        @user.roles_for?(Context).should be_false
      end

      it "should return true if any roles are assigned to the subject within the provided context" do
        nil_admin = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        class_admin = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context')
        class_mod = Role.create(:name => 'Moderator', :slug => 'moderator', :level => 80, :context_type => 'Context')
        @user.assign_role(nil_admin, Context)
        @user.assign_role(class_admin, Context)
        @user.assign_role(class_mod, Context)
        @user.roles_for?(Context).should be_true
      end
      
      context "when forcing context" do
        it "should only evaluate roles that match the context exactly" do
          admin_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
          @user.assign_role(admin_role, nil)
          @user.roles_for?(nil).should be_true
          @user.roles_for?(Context).should be_true
          @user.roles_for?(Context, true).should be_false
        end
      end
    end
  end

  describe "PermissionMethods" do
    before(:each) do
      User.acts_as_authorization_subject
      Role.acts_as_authorization_role
      Permission.acts_as_authorization_permission
    end

    it "should provide the model with has_many associations for permission_subjects and permissions" do
      user = User.create(:name => "Test User")
      User.reflections.keys.should include(:permission_users)
      User.reflections.keys.should include(:permissions)
      user.should respond_to(:permission_users)
      user.should respond_to(:permissions)
    end
  
    it "should use :dependent => :destroy for the permission_subjects association" do
      permission = Permission.create(:name => 'Edit', :slug => 'edit')
      user = User.create(:name => 'Tester')
      user.assign_permission(:edit)
      PermissionUser.count.should == 1
      user.destroy
      PermissionUser.count.should == 0
    end

    it "should use the reflection classes to create the has_many associations" do
      Soldier.acts_as_authorization_subject :permission_class => :skill, :role_class => :rank
      Skill.acts_as_authorization_permission :subject_class => :soldier, :role_class => :rank
      soldier = Soldier.create(:name => "Test User")
      Soldier.reflections.keys.should include(:skill_soldiers)
      Soldier.reflections.keys.should include(:skills)
      soldier.should respond_to(:skill_soldiers)
      soldier.should respond_to(:skills)
    end
    
    describe "assign_permission" do
      before(:each) do
        @user = User.create(:name => "Test User")
      end
      
      it "should require a permission object or slug" do
        expect { @user.assign_permission }.to raise_exception
      end

      it "should accept an optional context" do
        permission = Permission.create(:name => 'Edit', :slug => 'edit')
        expect { @user.assign_permission(:edit, nil) }.to_not raise_exception
      end

      it "should use nil context when none is provided" do
        permission = Permission.create(:name => 'Edit', :slug => 'edit')
        permission_user = @user.assign_permission(:edit)
        permission_user.id.should_not be_nil
        permission_user.context_type.should be_nil
      end

      it "should use the context when one is provided" do
        permission = Permission.create(:name => 'Edit', :slug => 'edit')
        context = Context.create(:name => "Test Context")
        
        class_permission_user = @user.assign_permission(permission, Context)
        class_permission_user.id.should_not be_nil
        class_permission_user.context_type.should == 'Context'
        class_permission_user.context_id.should be_nil
        
        inst_permission_user = @user.assign_permission(permission, context)
        inst_permission_user.id.should_not be_nil
        inst_permission_user.context_type.should == 'Context'
        inst_permission_user.context_id.should == context.id
      end

      it "should use target_permission to lookup the closest contextual match when a permission slug is provided" do
        context = Context.create(:name => "Test Context")
        nil_permission = Permission.create(:name => 'Edit', :slug => 'edit')
        class_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context')
        inst_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context', :context_id => context.id)
        
        nil_permission_user = @user.assign_permission(:edit, nil)
        nil_permission_user.id.should_not be_nil
        nil_permission_user.context_type.should be_nil
        nil_permission_user.context_id.should be_nil
        nil_permission_user.permission.id.should == nil_permission.id
        
        class_permission_user = @user.assign_permission(:edit, Context)
        class_permission_user.id.should_not be_nil
        class_permission_user.context_type.should == 'Context'
        class_permission_user.context_id.should be_nil
        class_permission_user.permission.id.should == class_permission.id
        
        inst_permission_user = @user.assign_permission(:edit, context)
        inst_permission_user.id.should_not be_nil
        inst_permission_user.context_type.should == 'Context'
        inst_permission_user.context_id.should == context.id
        inst_permission_user.permission.id.should == inst_permission.id
      end

      it "should use the permission object when one is provided" do
        context = Context.create(:name => "Test Context")
        nil_permission = Permission.create(:name => 'Edit', :slug => 'edit')
        class_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context')
        inst_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context', :context_id => context.id)
        
        class_permission_user = @user.assign_permission(nil_permission, Context)
        class_permission_user.id.should_not be_nil
        class_permission_user.context_type.should == 'Context'
        class_permission_user.context_id.should be_nil
        class_permission_user.permission.id.should == nil_permission.id
        
        inst_permission_user = @user.assign_permission(nil_permission, context)
        inst_permission_user.id.should_not be_nil
        inst_permission_user.context_type.should == 'Context'
        inst_permission_user.context_id.should == context.id
        inst_permission_user.permission.id.should == nil_permission.id
      end

      it "should fail and return false if the provided permission is nil" do
        @user.assign_permission(nil).should be_false
        @user.assign_permission(nil, Context).should be_false
      end

      it "should fail and return false if the provided permission cannot be used within the provided context" do
        context = Context.create(:name => "Test Context")
        class_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context')
        inst_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context', :context_id => context.id)

        @user.assign_permission(class_permission, nil).should be_false
        @user.assign_permission(inst_permission, nil).should be_false
        @user.assign_permission(inst_permission, Context).should be_false
      end

      it "should create the permission_subjects record to link the subject to the provided permission" do
        permission = Permission.create(:name => 'Edit', :slug => 'edit')
        @user.assign_permission(permission)
        PermissionUser.where(:user_id => @user.id, :permission_id => permission.id).count.should == 1
      end

      it "should return the assigned permission if it is already assigned within the provided context" do 
        permission = Permission.create(:name => 'Edit', :slug => 'edit')
        context = Context.create(:name => "Test Context")
        @user.assign_permission(permission)
        @user.assign_permission(permission).should be_an_instance_of(PermissionUser)
        PermissionUser.where(:user_id => @user.id, :permission_id => permission.id, :context_type => nil, :context_id => nil).count.should == 1
        @user.assign_permission(permission, Context)
        @user.assign_permission(permission, Context).should be_an_instance_of(PermissionUser)
        PermissionUser.where(:user_id => @user.id, :permission_id => permission.id, :context_type => 'Context', :context_id => nil).count.should == 1
        @user.assign_permission(permission, context)
        @user.assign_permission(permission, context).should be_an_instance_of(PermissionUser)
        PermissionUser.where(:user_id => @user.id, :permission_id => permission.id, :context_type => 'Context', :context_id => context.id).count.should == 1
      end

      context "when forcing context" do
        it "should not go up the context chain to find the permission when a permission slug is provided" do
          context = Context.create(:name => "Test Context")
          
          nil_permission = Permission.create(:name => 'Edit', :slug => 'edit')
          nil_permission_user = @user.assign_permission(:edit, nil)
          nil_permission_user.id.should_not be_nil
          nil_permission_user.context_type.should be_nil
          nil_permission_user.context_id.should be_nil
          nil_permission_user.permission.id.should == nil_permission.id
          
          @user.assign_permission(:edit, Context, true).should be_false
          class_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context')
          class_permission_user = @user.assign_permission(:edit, Context, true)
          class_permission_user.id.should_not be_nil
          class_permission_user.context_type.should == 'Context'
          class_permission_user.context_id.should be_nil
          class_permission_user.permission.id.should == class_permission.id
          
          @user.assign_permission(:edit, context, true).should be_false
          inst_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context', :context_id => context.id)
          inst_permission_user = @user.assign_permission(:edit, context, true)
          inst_permission_user.id.should_not be_nil
          inst_permission_user.context_type.should == 'Context'
          inst_permission_user.context_id.should == context.id
          inst_permission_user.permission.id.should == inst_permission.id
        end
      end
    end

    describe "unassign_permission" do
      before(:each) do
        @user = User.create(:name => "Test User")
      end
      
      it "should require a permission object or slug" do
        expect { @user.unassign_permission }.to raise_exception
      end

      it "should accept an optional context" do
        permission = Permission.create(:name => 'Edit', :slug => 'edit')
        expect { @user.unassign_permission(:edit, nil) }.to_not raise_exception
      end

      it "should use nil context when none is provided" do
        permission = Permission.create(:name => 'Edit', :slug => 'edit')
        @user.assign_permission(:edit, nil)
        @user.assign_permission(:edit, Context)

        unassigned = @user.unassign_permission(:edit)
        unassigned.should be_an_instance_of(PermissionUser)
        permissions = PermissionUser.where(:user_id => @user.id, :permission_id => permission.id)
        permissions.length.should == 1
        permissions[0].context_type.should == 'Context'
      end

      it "should use target_permission to lookup the closest contextual match when a permission slug is provided" do
        context = Context.create(:name => "Test Context")
        nil_permission = Permission.create(:name => 'Edit', :slug => 'edit')
        class_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context')
        inst_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context', :context_id => context.id)
        @user.assign_permission(nil_permission, nil)
        @user.assign_permission(class_permission, Context)
        @user.assign_permission(nil_permission, Context)
        @user.assign_permission(inst_permission, context)
        @user.assign_permission(class_permission, context)
        
        @user.unassign_permission(:edit, context).permission_id.should == inst_permission.id
        @user.unassign_permission(:edit, context).should be_false
        @user.unassign_permission(:edit, Context).permission_id.should == class_permission.id
        @user.unassign_permission(:edit, Context).should be_false
      end

      it "should use the permission object when one is provided" do
        context = Context.create(:name => "Test Context")
        nil_permission = Permission.create(:name => 'Edit', :slug => 'edit')
        class_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context')
        inst_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context', :context_id => context.id)
        @user.assign_permission(nil_permission, nil)
        @user.assign_permission(class_permission, Context)
        @user.assign_permission(nil_permission, Context)
        @user.assign_permission(inst_permission, context)
        @user.assign_permission(class_permission, context)
        
        @user.unassign_permission(class_permission, context).permission_id.should == class_permission.id
        @user.unassign_permission(inst_permission, context).permission_id.should == inst_permission.id
        @user.unassign_permission(nil_permission, Context).permission_id.should == nil_permission.id
        @user.unassign_permission(class_permission, Context).permission_id.should == class_permission.id
      end

      it "should fail and return false if the provided permission is nil" do
        @user.unassign_permission(nil).should be_false
        @user.unassign_permission(nil, Context).should be_false
      end

      it "should remove the permission_subjects record that links the subject to the provided permission" do
        permission = Permission.create(:name => 'Edit', :slug => 'edit')
        @user.assign_permission(permission)
        PermissionUser.where(:user_id => @user.id, :permission_id => permission.id).count.should == 1
        @user.unassign_permission(permission)
        PermissionUser.where(:user_id => @user.id, :permission_id => permission.id).count.should == 0
      end

      it "should fail and return false if the provided permission is not assigned in the provided context" do
        context = Context.create(:name => "Test Context")
        nil_permission = Permission.create(:name => 'Edit', :slug => 'edit')
        class_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context')
        inst_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context', :context_id => context.id)
        @user.assign_permission(nil_permission, Context)
        @user.assign_permission(class_permission, context)
        
        @user.unassign_permission(inst_permission, context).should be_false
        @user.unassign_permission(nil_permission, nil).should be_false
        @user.unassign_permission(class_permission, Context).should be_false
      end
      
      context "when forcing context" do
        it "should not go up the context chain to find the permission when a permission slug is provided" do
          context = Context.create(:name => "Test Context")
          nil_permission = Permission.create(:name => 'Edit', :slug => 'edit')
          class_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context')
          inst_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context', :context_id => context.id)
          @user.assign_permission(nil_permission, nil)
          @user.assign_permission(class_permission, Context)
          @user.assign_permission(nil_permission, Context)
          @user.assign_permission(inst_permission, context)
          @user.assign_permission(class_permission, context)
          
          @user.unassign_permission(:edit, context, true).permission_id.should == inst_permission.id
          inst_permission.destroy
          @user.unassign_permission(:edit, context, true).should be_false
          @user.unassign_permission(:edit, Context, true).permission_id.should == class_permission.id
          class_permission.destroy
          @user.unassign_permission(:edit, Context, true).should be_false
        end
      end
    end

    describe "has_permission?" do
      before(:each) do
        @user = User.create(:name => "Test User")
      end
      
      it "should require a permission object or slug" do
        expect { @user.has_permission? }.to raise_exception
      end

      it "should accept an optional context" do
        permission = Permission.create(:name => 'Edit', :slug => 'edit')
        expect { @user.has_permission?(:edit, nil) }.to_not raise_exception
      end

      it "should use nil context when none is provided" do
        permission = Permission.create(:name => 'Edit', :slug => 'edit')
        @user.assign_permission(:edit, Context)
        @user.has_permission?(:edit).should be_false
        @user.assign_permission(:edit, nil)
        @user.has_permission?(:edit).should be_true
      end

      it "should use target_permission to lookup the closest contextual match when a permission slug is provided" do
        context = Context.create(:name => "Test Context")
        nil_permission = Permission.create(:name => 'Edit', :slug => 'edit')
        class_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context')
        inst_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context', :context_id => context.id)
        @user.assign_permission(nil_permission, Context)
        @user.assign_permission(class_permission, context)
        
        @user.has_permission?(:edit, Context).should be_false
        @user.has_permission?(:edit, context).should be_false
        
        @user.assign_permission(class_permission, Context)
        @user.assign_permission(inst_permission, context)
        
        @user.has_permission?(:edit, Context).should be_true
        @user.has_permission?(:edit, context).should be_true
      end

      it "should use the permission object when one is provided" do
        context = Context.create(:name => "Test Context")
        nil_permission = Permission.create(:name => 'Edit', :slug => 'edit')
        class_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context')
        inst_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context', :context_id => context.id)
        @user.assign_permission(nil_permission, Context)
        @user.assign_permission(class_permission, context)
        
        @user.has_permission?(nil_permission, Context).should be_true
        @user.has_permission?(class_permission, context).should be_true
        @user.has_permission?(class_permission, Context).should be_false
        @user.has_permission?(inst_permission, context).should be_false
        
        @user.assign_permission(class_permission, Context)
        @user.assign_permission(inst_permission, context)
        
        @user.has_permission?(class_permission, Context).should be_true
        @user.has_permission?(inst_permission, context).should be_true
      end

      it "should return false if the provided permission is nil" do
        @user.has_permission?(nil).should be_false
        @user.has_permission?(nil, Context).should be_false
      end

      it "should look up the context chain for the assigned permission" do
        context = Context.create(:name => "Test Context")
        permission = Permission.create(:name => 'Edit', :slug => 'edit')
        @user.assign_permission(permission, nil)
        @user.has_permission?(:edit, Context).should be_true
        @user.has_permission?(:edit, context).should be_true
        @user.unassign_permission(permission, nil)
        @user.assign_permission(permission, Context)
        @user.has_permission?(:edit, context).should be_true
      end

      it "should return false if the provided permission is not assigned to the subject within the context chain" do
        context = Context.create(:name => "Test Context")
        permission = Permission.create(:name => 'Edit', :slug => 'edit')
        @user.has_permission?(permission, context).should be_false
        @user.has_permission?(:edit, Context).should be_false
        @user.has_permission?(permission, nil).should be_false
        
        @user.assign_permission(:edit, context)
        @user.has_permission?(:edit, context).should_not be_false
        @user.has_permission?(permission, Context).should be_false
        @user.has_permission?(:edit, nil).should be_false
        
        @user.assign_permission(:edit, Context)
        @user.has_permission?(:edit, context).should_not be_false
        @user.has_permission?(permission, Context).should_not be_false
        @user.has_permission?(permission, nil).should be_false
      end
      
      context "when forcing context" do
        it "should not go up the context chain to find the permission when a permission slug is provided" do
          context = Context.create(:name => "Test Context")
          nil_permission = Permission.create(:name => 'Edit', :slug => 'edit')
          @user.assign_permission(nil_permission, Context)
          @user.has_permission?(:edit, Context, false).should be_true
          @user.has_permission?(:edit, Context, true).should be_false
          
          class_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context')
          @user.assign_permission(class_permission, context)
          @user.has_permission?(:edit, context, false).should be_true
          @user.has_permission?(:edit, context, true).should be_false
        end
      end
    end

    describe "permissions_for" do
      before(:each) do
        @user = User.create(:name => "Test User")
      end
      
      it "should accept an optional context" do
        expect { @user.permissions_for(nil) }.to_not raise_exception
      end
      
      it "should use nil context when none is provided" do
        edit_permission = Permission.create(:name => 'Edit', :slug => 'edit')
        @user.assign_permission(edit_permission, Context)
        @user.permissions_for.length.should == 0
        @user.assign_permission(edit_permission, nil)
        @user.permissions_for.length.should == 1
      end

      it "should return an empty association array if no permissions are assigned to the subject within the provided context" do
        context = Context.create(:name => "Test Context")
        permission = Permission.create(:name => 'Edit', :slug => 'edit')
        @user.assign_permission(permission, context)
        @user.permissions_for(nil).length.should == 0
        @user.permissions_for(Context).length.should == 0
      end

      it "should return all permissions assigned to the subject within the provided context" do
        nil_edit = Permission.create(:name => 'Edit', :slug => 'edit')
        class_edit = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context')
        class_view = Permission.create(:name => 'View', :slug => 'view', :context_type => 'Context')
        @user.assign_permission(nil_edit, Context)
        @user.assign_permission(class_edit, Context)
        @user.assign_permission(class_view, Context)
        @user.permissions_for(Context).length.should == 3
      end
      
      context "when forcing context" do
        it "should only return permissions that match the context exactly" do
          edit_permission = Permission.create(:name => 'Edit', :slug => 'edit')
          view_permission = Permission.create(:name => 'View', :slug => 'view')
          @user.assign_permission(edit_permission, nil)
          @user.assign_permission(view_permission, nil)
          @user.permissions_for(nil).length.should == 2
          @user.permissions_for(Context).length.should == 2
          @user.permissions_for(Context, true).length.should == 0
        end
      end
    end

    describe "permissions_for?" do
      before(:each) do
        @user = User.create(:name => "Test User")
      end
      
      it "should accept an optional context" do
        expect { @user.permissions_for?(nil) }.to_not raise_exception
      end
      
      it "should use nil context when none is provided" do
        edit_permission = Permission.create(:name => 'Edit', :slug => 'edit')
        @user.assign_permission(edit_permission, Context)
        @user.permissions_for?.should be_false
        @user.assign_permission(edit_permission, nil)
        @user.permissions_for?.should be_true
      end

      it "should return false if no permissions are assigned to the subject within the provided context" do
        context = Context.create(:name => "Test Context")
        permission = Permission.create(:name => 'Edit', :slug => 'edit')
        @user.assign_permission(permission, context)
        @user.permissions_for?(nil).should be_false
        @user.permissions_for?(Context).should be_false
      end

      it "should return true if any permissions are assigned to the subject within the provided context" do
        nil_edit = Permission.create(:name => 'Edit', :slug => 'edit')
        class_edit = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context')
        class_view = Permission.create(:name => 'View', :slug => 'view', :context_type => 'Context')
        @user.assign_permission(nil_edit, Context)
        @user.assign_permission(class_edit, Context)
        @user.assign_permission(class_view, Context)
        @user.permissions_for?(Context).should be_true
      end
      
      context "when forcing context" do
        it "should only evaluate permissions that match the context exactly" do
          edit_permission = Permission.create(:name => 'Edit', :slug => 'edit')
          @user.assign_permission(edit_permission, nil)
          @user.permissions_for?(nil).should be_true
          @user.permissions_for?(Context).should be_true
          @user.permissions_for?(Context, true).should be_false
        end
      end
    end
    
  end
end
