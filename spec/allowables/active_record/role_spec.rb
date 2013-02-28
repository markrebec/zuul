require 'spec_helper'

describe "Allowables::ActiveRecord::Role" do

  context "validations for core role fields" do
    before(:each) do
      Role.acts_as_authorization_role
    end
    
    it "should validate presence of level" do
      role = Role.new(:name => 'Admin', :slug => 'admin')
      role.valid?.should be_false
      role.errors.keys.should include(:level)
    end

    it "should validate presence of name" do
      role = Role.new(:slug => 'admin', :level => 100)
      role.valid?.should be_false
      role.errors.keys.should include(:name)
    end

    it "should validate presence of slug" do
      role = Role.new(:name => 'Admin', :level => 100)
      role.valid?.should be_false
      role.errors.keys.should include(:slug)
    end

    it "should validate format of slug" do
      role = Role.new(:name => 'Admin', :slug => 'admin', :level => 100)
      role.valid?.should be_true
      role.slug = 'adm in'
      role.valid?.should be_false
      role.errors.keys.should include(:slug)
      role.slug = 'ad*&^;'
      role.valid?.should be_false
      role.errors.keys.should include(:slug)
      role.slug = '{:admin}'
      role.valid?.should be_false
      role.errors.keys.should include(:slug)
    end

    it "should validate uniqueness of slug scoped to context_type, context_id" do
      Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
      role = Role.new(:name => 'Admin', :slug => 'admin', :level => 100)
      role.valid?.should be_false
      role.errors.keys.should include(:slug)
      
      Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context').valid?.should be_true
      role = Role.new(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context')
      role.valid?.should be_false
      role.errors.keys.should include(:slug)
      
      Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context', :context_id => 1).valid?.should be_true
      role = Role.new(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context', :context_id => 1)
      role.valid?.should be_false
      role.errors.keys.should include(:slug)
    end

    it "should validate uniqueness of level scoped to context_type, context_id" do
      Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
      role = Role.new(:name => 'Admin', :slug => 'admin', :level => 100)
      role.valid?.should be_false
      role.errors.keys.should include(:level)
      
      Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context').valid?.should be_true
      role = Role.new(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context')
      role.valid?.should be_false
      role.errors.keys.should include(:level)
      
      Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context', :context_id => 1).valid?.should be_true
      role = Role.new(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context', :context_id => 1)
      role.valid?.should be_false
      role.errors.keys.should include(:level)
    end

    it "should validate numericality of level with integers only" do
      role = Role.new(:name => 'Admin', :slug => 'admin', :level => 'a')
      role.valid?.should be_false
      role.errors.keys.should include(:level)
      role.level = 1.3
      role.valid?.should be_false
      role.errors.keys.should include(:level)
    end
  end

  it "should provide the model with has_many relationships for role_subjects and subjects" do
    Role.acts_as_authorization_role
    Role.reflections.keys.should include(:role_users)
    Role.reflections.keys.should include(:users)
    role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
    role.should respond_to(:role_users)
    role.should respond_to(:users)
  end
  
  it "should use the reflection classes to create the has_many relationships" do
    Rank.acts_as_authorization_role :subject_class => :soldier, :with_permissions => false
    Rank.reflections.keys.should include(:rank_soldiers)
    Rank.reflections.keys.should include(:soldiers)
    rank = Rank.create(:name => 'General', :slug => 'general', :level => 100)
    rank.should respond_to(:rank_soldiers)
    rank.should respond_to(:soldiers)
  end
  
  context "with permissions disabled" do
    before(:each) do
      Role.acts_as_authorization_role :with_permissions => false
    end

    it "should not provide the model with has_many relationships for permission_roles and permissions" do
      Role.reflections.keys.should_not include(:permission_roles)
      Role.reflections.keys.should_not include(:permissions)
      role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
      role.should_not respond_to(:permission_roles)
      role.should_not respond_to(:permissions)
    end

    it "should not provide the model with permissions methods" do
      role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
      role.should_not respond_to(:assign_permission)
      role.should_not respond_to(:unassign_permission)
      role.should_not respond_to(:has_permission?)
      role.should_not respond_to(:permissions_for)
      role.should_not respond_to(:permissions_for?)
    end
  end

  context "with permissions enabled" do
    before(:each) do
      Role.acts_as_authorization_role
      Permission.acts_as_authorization_permission
    end
    
    it "should provide the model with has_many relationships for permission_roles and permissions" do
      Role.reflections.keys.should include(:permission_roles)
      Role.reflections.keys.should include(:permissions)
      role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
      role.should respond_to(:permission_roles)
      role.should respond_to(:permissions)
    end
    
    it "should use the reflection classes to create the has_many relationships" do
      Rank.acts_as_authorization_role :subject_class => :soldier, :permission_class => :skill
      Rank.reflections.keys.should include(:rank_skills)
      Rank.reflections.keys.should include(:skills)
      rank = Rank.create(:name => 'General', :slug => 'general', :level => 100)
      rank.should respond_to(:rank_skills)
      rank.should respond_to(:skills)
    end

    describe "assign_permission" do
      before(:each) do
        @role = Role.create(:name => "Admin", :slug => "admin", :level => 100)
      end
      
      it "should require a permission object or slug" do
        expect { @role.assign_permission }.to raise_exception
      end

      it "should accept an optional context" do
        permission = Permission.create(:name => 'Edit', :slug => 'edit')
        expect { @role.assign_permission(:edit, nil) }.to_not raise_exception
      end

      it "should use nil context when none is provided" do
        permission = Permission.create(:name => 'Edit', :slug => 'edit')
        permission_role = @role.assign_permission(:edit)
        permission_role.id.should_not be_nil
        permission_role.context_type.should be_nil
      end

      it "should use the context when one is provided" do
        permission = Permission.create(:name => 'Edit', :slug => 'edit')
        context = Context.create(:name => "Test Context")
        
        class_permission_role = @role.assign_permission(permission, Context)
        class_permission_role.id.should_not be_nil
        class_permission_role.context_type.should == 'Context'
        class_permission_role.context_id.should be_nil
        
        inst_permission_role = @role.assign_permission(permission, context)
        inst_permission_role.id.should_not be_nil
        inst_permission_role.context_type.should == 'Context'
        inst_permission_role.context_id.should == context.id
      end
      
      it "should use target_permission to lookup the closest contextual match when a permission slug is provided" do
        context = Context.create(:name => "Test Context")
        nil_permission = Permission.create(:name => 'Edit', :slug => 'edit')
        class_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context')
        inst_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context', :context_id => context.id)
        
        nil_permission_role = @role.assign_permission(:edit, nil)
        nil_permission_role.id.should_not be_nil
        nil_permission_role.context_type.should be_nil
        nil_permission_role.context_id.should be_nil
        nil_permission_role.permission.should == nil_permission
        
        class_permission_role = @role.assign_permission(:edit, Context)
        class_permission_role.id.should_not be_nil
        class_permission_role.context_type.should == 'Context'
        class_permission_role.context_id.should be_nil
        class_permission_role.permission.should == class_permission
        
        inst_permission_role = @role.assign_permission(:edit, context)
        inst_permission_role.id.should_not be_nil
        inst_permission_role.context_type.should == 'Context'
        inst_permission_role.context_id.should == context.id
        inst_permission_role.permission.should == inst_permission
      end

      it "should use the permission object when one is provided" do
        context = Context.create(:name => "Test Context")
        nil_permission = Permission.create(:name => 'Edit', :slug => 'edit')
        class_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context')
        inst_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context', :context_id => context.id)
        
        class_permission_role = @role.assign_permission(nil_permission, Context)
        class_permission_role.id.should_not be_nil
        class_permission_role.context_type.should == 'Context'
        class_permission_role.context_id.should be_nil
        class_permission_role.permission.id.should == nil_permission.id
        
        inst_permission_role = @role.assign_permission(nil_permission, context)
        inst_permission_role.id.should_not be_nil
        inst_permission_role.context_type.should == 'Context'
        inst_permission_role.context_id.should == context.id
        inst_permission_role.permission.id.should == nil_permission.id
      end

      it "should fail and return false if the provided permission is nil" do
        @role.assign_permission(nil).should be_false
        @role.assign_permission(nil, Context).should be_false
      end
      
      it "should fail and return false if the provided permission cannot be used within the provided context" do
        context = Context.create(:name => "Test Context")
        class_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context')
        inst_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context', :context_id => context.id)

        @role.assign_permission(class_permission, nil).should be_false
        @role.assign_permission(inst_permission, nil).should be_false
        @role.assign_permission(inst_permission, Context).should be_false
      end

      it "should create the permission_subjects record to link the subject to the provided permission" do
        permission = Permission.create(:name => 'Edit', :slug => 'edit')
        @role.assign_permission(permission)
        PermissionRole.where(:role_id => @role.id, :permission_id => permission.id).count.should == 1
      end

      it "should fail and return false if the provided permission is already assigned in the provided context" do
        permission = Permission.create(:name => 'Edit', :slug => 'edit')
        context = Context.create(:name => "Test Context")
        @role.assign_permission(permission)
        @role.assign_permission(permission).should be_false
        @role.assign_permission(permission, Context)
        @role.assign_permission(permission, Context).should be_false
        @role.assign_permission(permission, context)
        @role.assign_permission(permission, context).should be_false
      end
    end

    describe "unassign_permission" do
      before(:each) do
        @role = Role.create(:name => "Admin", :slug => "admin", :level => 100)
      end
      
      it "should require a permission object or slug" do
        expect { @role.unassign_permission }.to raise_exception
      end

      it "should accept an optional context" do
        permission = Permission.create(:name => 'Edit', :slug => 'edit')
        expect { @role.unassign_permission(:edit, nil) }.to_not raise_exception
      end

      it "should use nil context when none is provided" do
        permission = Permission.create(:name => 'Edit', :slug => 'edit')
        @role.assign_permission(:edit, nil)
        @role.assign_permission(:edit, Context)

        unassigned = @role.unassign_permission(:edit)
        unassigned.should be_an_instance_of(PermissionRole)
        permissions = PermissionRole.where(:role_id => @role.id, :permission_id => permission.id)
        permissions.length.should == 1
        permissions[0].context_type.should == 'Context'
      end

      it "should use target_permission to lookup the closest contextual match when a permission slug is provided" do
        context = Context.create(:name => "Test Context")
        nil_permission = Permission.create(:name => 'Edit', :slug => 'edit')
        class_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context')
        inst_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context', :context_id => context.id)
        @role.assign_permission(nil_permission, nil)
        @role.assign_permission(class_permission, Context)
        @role.assign_permission(nil_permission, Context)
        @role.assign_permission(inst_permission, context)
        @role.assign_permission(class_permission, context)
        
        @role.unassign_permission(:edit, context).permission_id.should == inst_permission.id
        @role.unassign_permission(:edit, context).should be_false
        @role.unassign_permission(:edit, Context).permission_id.should == class_permission.id
        @role.unassign_permission(:edit, Context).should be_false
      end
      
      it "should use the permission object when one is provided" do
        context = Context.create(:name => "Test Context")
        nil_permission = Permission.create(:name => 'Edit', :slug => 'edit')
        class_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context')
        inst_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context', :context_id => context.id)
        @role.assign_permission(nil_permission, nil)
        @role.assign_permission(class_permission, Context)
        @role.assign_permission(nil_permission, Context)
        @role.assign_permission(inst_permission, context)
        @role.assign_permission(class_permission, context)
        
        @role.unassign_permission(class_permission, context).permission_id.should == class_permission.id
        @role.unassign_permission(inst_permission, context).permission_id.should == inst_permission.id
        @role.unassign_permission(nil_permission, Context).permission_id.should == nil_permission.id
        @role.unassign_permission(class_permission, Context).permission_id.should == class_permission.id
      end

      it "should fail and return false if the provided permission is nil" do
        @role.unassign_permission(nil).should be_false
        @role.unassign_permission(nil, Context).should be_false
      end

      it "should remove the permission_subjects record that links the subject to the provided permission" do
        permission = Permission.create(:name => 'Edit', :slug => 'edit')
        @role.assign_permission(permission)
        PermissionRole.where(:role_id => @role.id, :permission_id => permission.id).count.should == 1
        @role.unassign_permission(permission)
        PermissionRole.where(:role_id => @role.id, :permission_id => permission.id).count.should == 0
      end

      it "should fail and return false if the provided permission is not assigned in the provided context" do
        context = Context.create(:name => "Test Context")
        nil_permission = Permission.create(:name => 'Edit', :slug => 'edit')
        class_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context')
        inst_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context', :context_id => context.id)
        @role.assign_permission(nil_permission, Context)
        @role.assign_permission(class_permission, context)
        
        @role.unassign_permission(inst_permission, context).should be_false
        @role.unassign_permission(nil_permission, nil).should be_false
        @role.unassign_permission(class_permission, Context).should be_false
      end
    end

    describe "has_permission?" do
      before(:each) do
        @role = Role.create(:name => "Admin", :slug => "admin", :level => 100)
      end
      
      it "should require a permission object or slug" do
        expect { @role.has_permission? }.to raise_exception
      end

      it "should accept an optional context" do
        permission = Permission.create(:name => 'Edit', :slug => 'edit')
        expect { @role.has_permission?(:edit, nil) }.to_not raise_exception
      end

      it "should use nil context when none is provided" do
        permission = Permission.create(:name => 'Edit', :slug => 'edit')
        @role.assign_permission(:edit, Context)
        @role.has_permission?(:edit).should be_false
        @role.assign_permission(:edit, nil)
        @role.has_permission?(:edit).should be_true
      end

      it "should use target_permission to lookup the closest contextual match when a permission slug is provided" do
        context = Context.create(:name => "Test Context")
        nil_permission = Permission.create(:name => 'Edit', :slug => 'edit')
        class_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context')
        inst_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context', :context_id => context.id)
        @role.assign_permission(nil_permission, Context)
        @role.assign_permission(class_permission, context)
        
        @role.has_permission?(:edit, Context).should be_false
        @role.has_permission?(:edit, context).should be_false
        
        @role.assign_permission(class_permission, Context)
        @role.assign_permission(inst_permission, context)
        
        @role.has_permission?(:edit, Context).should be_true
        @role.has_permission?(:edit, context).should be_true
      end
      
      it "should use the permission object when one is provided" do
        context = Context.create(:name => "Test Context")
        nil_permission = Permission.create(:name => 'Edit', :slug => 'edit')
        class_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context')
        inst_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context', :context_id => context.id)
        @role.assign_permission(nil_permission, Context)
        @role.assign_permission(class_permission, context)
        
        @role.has_permission?(nil_permission, Context).should be_true
        @role.has_permission?(class_permission, context).should be_true
        @role.has_permission?(class_permission, Context).should be_false
        @role.has_permission?(inst_permission, context).should be_false
        
        @role.assign_permission(class_permission, Context)
        @role.assign_permission(inst_permission, context)
        
        @role.has_permission?(class_permission, Context).should be_true
        @role.has_permission?(inst_permission, context).should be_true
      end

      it "should return false if the provided permission is nil" do
        @role.has_permission?(nil).should be_false
        @role.has_permission?(nil, Context).should be_false
      end

      it "should look up the context chain for the assigned permission" do
        context = Context.create(:name => "Test Context")
        permission = Permission.create(:name => 'Edit', :slug => 'edit')
        @role.assign_permission(permission, nil)
        @role.has_permission?(:edit, Context).should be_true
        @role.has_permission?(:edit, context).should be_true
        @role.unassign_permission(permission, nil)
        @role.assign_permission(permission, Context)
        @role.has_permission?(:edit, context).should be_true
      end
      
      it "should return false if the provided permission is not assigned to the subject within the context chain" do
        context = Context.create(:name => "Test Context")
        permission = Permission.create(:name => 'Edit', :slug => 'edit')
        @role.has_permission?(permission, context).should be_false
        @role.has_permission?(:edit, Context).should be_false
        @role.has_permission?(permission, nil).should be_false
        
        @role.assign_permission(:edit, context)
        @role.has_permission?(:edit, context).should_not be_false
        @role.has_permission?(permission, Context).should be_false
        @role.has_permission?(:edit, nil).should be_false
        
        @role.assign_permission(:edit, Context)
        @role.has_permission?(:edit, context).should_not be_false
        @role.has_permission?(permission, Context).should_not be_false
        @role.has_permission?(permission, nil).should be_false
      end
    end

    describe "permissions_for" do
      before(:each) do
        @role = Role.create(:name => "Admin", :slug => "admin", :level => 100)
      end
      
      it "should accept an optional context" do
        expect { @role.permissions_for(nil) }.to_not raise_exception
      end
      
      it "should use nil context when none is provided" do
        edit_permission = Permission.create(:name => 'Edit', :slug => 'edit')
        @role.assign_permission(edit_permission, Context)
        @role.permissions_for.length.should == 0
        @role.assign_permission(edit_permission, nil)
        @role.permissions_for.length.should == 1
      end

      it "should return an empty association array if no permissions are assigned to the subject within the provided context" do
        context = Context.create(:name => "Test Context")
        permission = Permission.create(:name => 'Edit', :slug => 'edit')
        @role.assign_permission(permission, context)
        @role.permissions_for(nil).length.should == 0
        @role.permissions_for(Context).length.should == 0
      end

      it "should return all permissions assigned to the subject within the provided context" do
        nil_edit = Permission.create(:name => 'Edit', :slug => 'edit')
        class_edit = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context')
        class_view = Permission.create(:name => 'View', :slug => 'view', :context_type => 'Context')
        @role.assign_permission(nil_edit, Context)
        @role.assign_permission(class_edit, Context)
        @role.assign_permission(class_view, Context)
        @role.permissions_for(Context).length.should == 3
      end
    end

    describe "permissions_for?" do
      before(:each) do
        @role = Role.create(:name => "Admin", :slug => "admin", :level => 100)
      end
      
      it "should accept an optional context" do
        expect { @role.permissions_for?(nil) }.to_not raise_exception
      end
      
      it "should use nil context when none is provided" do
        edit_permission = Permission.create(:name => 'Edit', :slug => 'edit')
        @role.assign_permission(edit_permission, Context)
        @role.permissions_for?.should be_false
        @role.assign_permission(edit_permission, nil)
        @role.permissions_for?.should be_true
      end

      it "should return false if no permissions are assigned to the subject within the provided context" do
        context = Context.create(:name => "Test Context")
        permission = Permission.create(:name => 'Edit', :slug => 'edit')
        @role.assign_permission(permission, context)
        @role.permissions_for?(nil).should be_false
        @role.permissions_for?(Context).should be_false
      end

      it "should return true if any permissions are assigned to the subject within the provided context" do
        nil_edit = Permission.create(:name => 'Edit', :slug => 'edit')
        class_edit = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context')
        class_view = Permission.create(:name => 'View', :slug => 'view', :context_type => 'Context')
        @role.assign_permission(nil_edit, Context)
        @role.assign_permission(class_edit, Context)
        @role.assign_permission(class_view, Context)
        @role.permissions_for?(Context).should be_true
      end
    end
  end
end
