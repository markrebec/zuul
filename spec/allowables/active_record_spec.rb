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
      before(:each) do
        Dummy.send :include, Allowables::ActiveRecord
        Dummy.send :include, Allowables::ActiveRecord::AuthorizationMethods
      end

      it "should require a role object or slug and a context" do
        expect { Dummy.new.target_role }.to raise_exception
        expect { Dummy.new.target_role(:role) }.to raise_exception
        expect { Dummy.new.target_role(:role, nil) }.to_not raise_exception
      end

      it "should accept a role object" do
        expect { Dummy.new.target_role(Role.new, nil) }.to_not raise_exception
      end

      it "should accept a string or symbol" do
        expect { Dummy.new.target_role(:role, nil) }.to_not raise_exception
        expect { Dummy.new.target_role('role', nil) }.to_not raise_exception
      end
      
      context "when looking up a role" do
        it "should just return the role object if one is passed" do
          role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
          Dummy.new.target_role(role, nil).should === role
        end

        it "should use the defined role_class for the lookup" do
          role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
          Dummy.new.target_role(:admin, nil).should be_an_instance_of(Role)
          # TODO add another example that uses different role class
        end

        it "should use the provided slug for the lookup" do
          role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
          Dummy.new.target_role(:admin, nil).slug.should == 'admin'
          Dummy.new.target_role('admin', nil).slug.should == 'admin'
        end

        it "should normalize symbols and strings to lowercase and underscored" do
          role = Role.create(:name => 'My Cool Role', :slug => 'my_cool_role', :level => 40)
          Dummy.new.target_role('MyCoolRole', nil).should == role
          Dummy.new.target_role(:MyCoolRole, nil).should == role
        end
        
        context "within a context" do
          it "should go up the context chain to find roles" do
            context = Context.create(:name => "Test Context")
            nil_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
            Dummy.new.target_role(:admin, nil).should == nil_role
            Dummy.new.target_role(:admin, Context).should == nil_role
            Dummy.new.target_role(:admin, context).should == nil_role
          end

          it "should use the closest contextual match" do
            context = Context.create(:name => "Test Context")
            
            nil_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
            Dummy.new.target_role(:admin, nil).should == nil_role
            Dummy.new.target_role(:admin, Context).should == nil_role
            Dummy.new.target_role(:admin, context).should == nil_role
            
            class_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context')
            Dummy.new.target_role(:admin, nil).should == nil_role
            Dummy.new.target_role(:admin, Context).should == class_role
            Dummy.new.target_role(:admin, context).should == class_role
            
            inst_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context', :context_id => context.id)
            Dummy.new.target_role(:admin, nil).should == nil_role
            Dummy.new.target_role(:admin, Context).should == class_role
            Dummy.new.target_role(:admin, context).should == inst_role
          end
        end
      end
    end

    describe "target_permission" do
      before(:each) do
        Dummy.send :include, Allowables::ActiveRecord
        Dummy.send :include, Allowables::ActiveRecord::AuthorizationMethods
      end

      it "should require a permission object or slug and a context" do
        expect { Dummy.new.target_permission }.to raise_exception
        expect { Dummy.new.target_permission(:permission) }.to raise_exception
        expect { Dummy.new.target_permission(:permission, nil) }.to_not raise_exception
      end

      it "should accept a permission object" do
        expect { Dummy.new.target_permission(Permission.new, nil) }.to_not raise_exception
      end

      it "should accept a string or symbol" do
        expect { Dummy.new.target_permission(:permission, nil) }.to_not raise_exception
        expect { Dummy.new.target_permission('permission', nil) }.to_not raise_exception
      end
      
      context "when looking up a permission" do
        it "should just return the permission object if one is passed" do
          permission = Permission.create(:name => 'Do Something', :slug => 'do_something')
          Dummy.new.target_permission(permission, nil).should === permission
        end

        it "should use the defined permission_class for the lookup" do
          permission = Permission.create(:name => 'Do Something', :slug => 'do_something')
          Dummy.new.target_permission(:do_something, nil).should be_an_instance_of(Permission)
          # TODO add another example that uses different permission class
        end

        it "should use the provided slug for the lookup" do
          permission = Permission.create(:name => 'Do Something', :slug => 'do_something')
          Dummy.new.target_permission(:do_something, nil).slug.should == 'do_something'
          Dummy.new.target_permission('do_something', nil).slug.should == 'do_something'
        end

        it "should normalize symbols and strings to lowercase and underscored" do
          permission = Permission.create(:name => 'My Cool Permission', :slug => 'my_cool_permission')
          Dummy.new.target_permission('MyCoolPermission', nil).should == permission
          Dummy.new.target_permission(:MyCoolPermission, nil).should == permission
        end
        
        context "within a context" do
          it "should go up the context chain to find permissions" do
            context = Context.create(:name => "Test Context")
            nil_permission = Permission.create(:name => 'Do Something', :slug => 'do_something')
            Dummy.new.target_permission(:do_something, nil).should == nil_permission
            Dummy.new.target_permission(:do_something, Context).should == nil_permission
            Dummy.new.target_permission(:do_something, context).should == nil_permission
          end

          it "should use the closest contextual match" do
            context = Context.create(:name => "Test Context")
            
            nil_permission = Permission.create(:name => 'Do Something', :slug => 'do_something')
            Dummy.new.target_permission(:do_something, nil).should == nil_permission
            Dummy.new.target_permission(:do_something, Context).should == nil_permission
            Dummy.new.target_permission(:do_something, context).should == nil_permission
            
            class_permission = Permission.create(:name => 'Do Something', :slug => 'do_something', :context_type => 'Context')
            Dummy.new.target_permission(:do_something, nil).should == nil_permission
            Dummy.new.target_permission(:do_something, Context).should == class_permission
            Dummy.new.target_permission(:do_something, context).should == class_permission
            
            inst_permission = Permission.create(:name => 'Do Something', :slug => 'do_something', :context_type => 'Context', :context_id => context.id)
            Dummy.new.target_permission(:do_something, nil).should == nil_permission
            Dummy.new.target_permission(:do_something, Context).should == class_permission
            Dummy.new.target_permission(:do_something, context).should == inst_permission
          end
        end
      end
    end

    describe "verify_target_context" do
      before(:each) do
        Dummy.send :include, Allowables::ActiveRecord
        Dummy.send :include, Allowables::ActiveRecord::AuthorizationMethods
      end
      
      it "should require a target role or permission and a context" do
        expect { Dummy.new.verify_target_context }.to raise_exception
        expect { Dummy.new.verify_target_context(nil) }.to raise_exception
      end

      it "should accept a role or a permission as the target" do
        role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        permission = Permission.create(:name => 'Do Something', :slug => 'do_something')
        Dummy.new.verify_target_context(role, nil).should == true
        Dummy.new.verify_target_context(permission, nil).should == true
      end

      it "should return false if a nil target is provided" do
        Dummy.new.verify_target_context(nil, nil).should == false
      end

      it "should allow nil context targets to be used within any other context" do
        context = Context.create(:name => "Test Context")
        role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        permission = Permission.create(:name => 'Do Something', :slug => 'do_something')
        Dummy.new.verify_target_context(role, nil).should == true
        Dummy.new.verify_target_context(role, Context).should == true
        Dummy.new.verify_target_context(role, context).should == true
        Dummy.new.verify_target_context(permission, nil).should == true
        Dummy.new.verify_target_context(permission, Context).should == true
        Dummy.new.verify_target_context(permission, context).should == true
      end

      it "should allow class context targets to be used within the context of their class or any instances of their class" do
        context = Context.create(:name => "Test Context")
        role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context')
        permission = Permission.create(:name => 'Do Something', :slug => 'do_something', :context_type => 'Context')
        Dummy.new.verify_target_context(role, Context).should == true
        Dummy.new.verify_target_context(role, context).should == true
        Dummy.new.verify_target_context(permission, Context).should == true
        Dummy.new.verify_target_context(permission, context).should == true
      end

      it "should allow instance targets to be used within their own instance context" do
        context = Context.create(:name => "Test Context")
        role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context', :context_id => context.id)
        permission = Permission.create(:name => 'Do Something', :slug => 'do_something', :context_type => 'Context', :context_id => context.id)
        Dummy.new.verify_target_context(role, context).should == true
        Dummy.new.verify_target_context(permission, context).should == true
      end
      
      it "should not allow class context targets to be used within any other class or nil contexts" do
        role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context')
        permission = Permission.create(:name => 'Do Something', :slug => 'do_something', :context_type => 'Context')
        Dummy.new.verify_target_context(role, nil).should == false
        Dummy.new.verify_target_context(role, Weapon).should == false
        Dummy.new.verify_target_context(permission, nil).should == false
        Dummy.new.verify_target_context(permission, Weapon).should == false
      end
      
      it "should not allow instance context targets to be used within any other class or instance contexts or a nil context" do
        context = Context.create(:name => "Test Context")
        other_context = Context.create(:name => "Another Test Context")
        role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context', :context_id => context.id)
        permission = Permission.create(:name => 'Do Something', :slug => 'do_something', :context_type => 'Context', :context_id => context.id)
        Dummy.new.verify_target_context(role, nil).should == false
        Dummy.new.verify_target_context(role, Context).should == false
        Dummy.new.verify_target_context(role, Weapon).should == false
        Dummy.new.verify_target_context(role, other_context).should == false
        Dummy.new.verify_target_context(permission, nil).should == false
        Dummy.new.verify_target_context(permission, Context).should == false
        Dummy.new.verify_target_context(permission, Weapon).should == false
        Dummy.new.verify_target_context(permission, other_context).should == false
      end
    end
  end

end
