require 'spec_helper'

describe "Zuul::ActiveRecord" do

  def prep_dummy
    Dummy.send :include, Zuul::ActiveRecord
    Dummy.send :instance_variable_set, :@auth_config, Zuul::Configuration.new
    Dummy.send :instance_variable_set, :@auth_scopes, {:default => Zuul::ActiveRecord::Scope.new(Zuul::Configuration.new)}
    Dummy.send :include, Zuul::ActiveRecord::AuthorizationMethods
  end

  it "should extend ActiveRecord::Base with Zuul::ActiveRecord" do
    ActiveRecord::Base.ancestors.include?(Zuul::ActiveRecord).should be_true
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
    it "should extend the model with Zuul::ActiveRecord::AuthorizationMethods" do
      User.acts_as_authorization_subject
      Role.acts_as_authorization_role
      Permission.acts_as_authorization_permission
      Context.acts_as_authorization_context
      [User, Role, Permission, Context].each do |model|
        model.ancestors.include?(Zuul::ActiveRecord::AuthorizationMethods).should be_true
      end
    end

    # TODO maybe move these into 4 different specs for each method?
    it "should allow passing class arguments to be used with reflections" do
      Soldier.acts_as_authorization_subject :role_class => Rank, :permission_class => Skill
      Soldier.auth_scope.role_class.should == Rank
      Soldier.auth_scope.permission_class.should == Skill

      Rank.acts_as_authorization_role :subject_class => Soldier, :permission_class => Skill
      Rank.auth_scope.subject_class.should == Soldier
      Rank.auth_scope.permission_class.should == Skill

      Skill.acts_as_authorization_permission :subject_class => Soldier, :role_class => Rank
      Skill.auth_scope.subject_class.should == Soldier
      Skill.auth_scope.role_class.should == Rank

      Weapon.acts_as_authorization_context :subject_class => Soldier, :role_class => Rank, :permission_class => Skill
      Weapon.auth_scope.permission_class.should == Skill
    end

    it "should allow class arguments to be provided as classes, strings or symbols" do
      Soldier.acts_as_authorization_subject :role_class => Rank, :permission_class => "Skill"
      Soldier.auth_scope.role_class.should == Rank
      Soldier.auth_scope.permission_class.should == Skill
      Rank.acts_as_authorization_role :subject_class => :soldier, :permission_class => "skill"
      Rank.auth_scope.subject_class.should == Soldier
      Rank.auth_scope.permission_class.should == Skill
      Skill.acts_as_authorization_permission :subject_class => Soldier, :role_class => :Rank
      Skill.auth_scope.subject_class.should == Soldier
      Skill.auth_scope.role_class.should == Rank
      Weapon.acts_as_authorization_context :subject_class => "soldier", :role_class => :rank, :permission_class => Skill
      Weapon.auth_scope.permission_class.should == Skill
    end

    it "should allow using namespaced classes" do
      ZuulModels::User.acts_as_authorization_subject :role_class => ZuulModels::Role, :permission_class => "ZuulModels::Permission"
      ZuulModels::User.auth_scope.role_class.should == ZuulModels::Role
      ZuulModels::User.auth_scope.permission_class.should == ZuulModels::Permission
      ZuulModels::User.auth_scope.role_subject_class.should == ZuulModels::RoleUser
      ZuulModels::User.auth_scope.permission_subject_class.should == ZuulModels::PermissionUser
      ZuulModels::User.auth_scope.permission_role_class.should == ZuulModels::PermissionRole

      ZuulModels::Role.acts_as_authorization_role :subject_class => ZuulModels::User, :permission_class => ZuulModels::Permission
      ZuulModels::Role.auth_scope.subject_class.should == ZuulModels::User
      ZuulModels::Role.auth_scope.permission_class.should == ZuulModels::Permission
      ZuulModels::Role.auth_scope.role_subject_class.should == ZuulModels::RoleUser
      ZuulModels::Role.auth_scope.permission_subject_class.should == ZuulModels::PermissionUser
      ZuulModels::Role.auth_scope.permission_role_class.should == ZuulModels::PermissionRole
      
      ZuulModels::Permission.acts_as_authorization_permission :subject_class => "ZuulModels::User", :role_class => ZuulModels::Role
      ZuulModels::Permission.auth_scope.subject_class.should == ZuulModels::User
      ZuulModels::Permission.auth_scope.role_class.should == ZuulModels::Role
      ZuulModels::Permission.auth_scope.role_subject_class.should == ZuulModels::RoleUser
      ZuulModels::Permission.auth_scope.permission_subject_class.should == ZuulModels::PermissionUser
      ZuulModels::Permission.auth_scope.permission_role_class.should == ZuulModels::PermissionRole
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
    it "should extend the model with Zuul::ActiveRecord::Subject" do
      User.acts_as_authorization_subject
      User.ancestors.include?(Zuul::ActiveRecord::Subject).should be_true
    end

    it "should extend the model with Zuul::ActiveRecord::Subject:RoleMethods" do
      User.acts_as_authorization_subject
      User.ancestors.include?(Zuul::ActiveRecord::Subject::RoleMethods).should be_true
    end
    
    it "should extend the model with Zuul::ActiveRecord::Subject:PermissionMethods if permissions enabled" do
      User.acts_as_authorization_subject
      User.ancestors.include?(Zuul::ActiveRecord::Subject::PermissionMethods).should be_true
    end
    
    it "should not extend the model with Zuul::ActiveRecord::Subject:PermissionMethods if permissions disabled" do
      User.acts_as_authorization_subject :with_permissions => false
      User.ancestors.include?(Zuul::ActiveRecord::Subject::PermissionMethods).should be_false
    end
  end

  describe "acts_as_authorization_role" do
    it "should extend the model with Zuul::ActiveRecord::Role" do
      Role.acts_as_authorization_role
      Role.ancestors.include?(Zuul::ActiveRecord::Role).should be_true
    end
    
    it "should extend the model with Zuul::ActiveRecord::ContextAccessors" do
      Role.acts_as_authorization_role
      Role.ancestors.include?(Zuul::ActiveRecord::ContextAccessors).should be_true
    end
    
    it "should extend the model with Zuul::ActiveRecord::Role::PermissionMethods if permissions enabled" do
      Role.acts_as_authorization_role
      Role.ancestors.include?(Zuul::ActiveRecord::Role::PermissionMethods).should be_true
    end
    
    it "should not extend the model with Zuul::ActiveRecord::Role::PermissionMethods if permissions disabled" do
      Role.acts_as_authorization_role :with_permissions => false
      Role.ancestors.include?(Zuul::ActiveRecord::Role::PermissionMethods).should be_false
    end
  end

  describe "acts_as_authorization_permission" do
    it "should extend the model with Zuul::ActiveRecord::Permission" do
      Permission.acts_as_authorization_permission
      Permission.ancestors.include?(Zuul::ActiveRecord::Permission).should be_true
    end
    
    it "should extend the model with Zuul::ActiveRecord::ContextAccessors" do
      Permission.acts_as_authorization_permission
      Permission.ancestors.include?(Zuul::ActiveRecord::ContextAccessors).should be_true
    end
  end

  describe "acts_as_authorization_context" do
    it "should extend the model with Zuul::ActiveRecord::Context" do
      Context.acts_as_authorization_context
      Context.ancestors.include?(Zuul::ActiveRecord::Context).should be_true
    end
  end

  describe "AuthorizationMethods" do
    describe "auth_scope" do
      before(:each) do
        Role.acts_as_authorization_role
        Permission.acts_as_authorization_permission
        User.acts_as_authorization_subject
        Level.acts_as_authorization_role :permission_class => :ability
        Ability.acts_as_authorization_permission :role_class => :level
        User.acts_as_authorization_subject :scope => :character, :role_class => :level, :permission_class => :ability
      end

      context "class method" do
        it "should return the requested scope" do
          User.auth_scope.name.should == :default
          User.auth_scope(:character).name.should == :character
        end

        it "should raise an exception if the scope doesn't exist" do
          expect { User.auth_scope(:noscope) }.to raise_exception(Zuul::Exceptions::UndefinedScope)
        end

        context "when calling a method" do
          it "should allow calling a method within the requested scope" do
            User.instance_eval do
              def scope_test_method
                role_class_name
              end
            end
            User.auth_scope(:character, :scope_test_method).should == User.auth_scope(:character).role_class_name
          end

          it "should allow calling a method with arguments within the requested scope" do
            suffix = rand(100)*rand(100)
            User.instance_eval do
              def scope_test_method(suf)
                "#{role_class_name}_#{suf}"
              end
            end
            User.auth_scope(:character, :scope_test_method, suffix).should == "#{User.auth_scope(:character).role_class_name}_#{suffix}"
          end
        end
        
        context "when passing a block" do
          it "should allow executing a block within the requested scope" do
            User.auth_scope(:character) do
              role_class_name
            end.should == User.auth_scope(:character).role_class_name
          end

          it "should allow executing a block with arguments within the requested scope" do
            suffix = rand(100)*rand(100)
            User.auth_scope(:character, suffix) do |suf|
              "#{role_class_name}_#{suf}"
            end.should == "#{User.auth_scope(:character).role_class_name}_#{suffix}"
          end
        end
      end

      context "instance method" do
        before(:each) do
          @user = User.create(:name => "Tester")
        end

        it "should return the requested scope" do
          @user.auth_scope.name.should == :default
          @user.auth_scope(:character).name.should == :character
        end

        it "should raise an exception if the scope doesn't exist" do
          expect { @user.auth_scope(:noscope) }.to raise_exception(Zuul::Exceptions::UndefinedScope)
        end

        context "when calling a method" do
          it "should allow calling a method within the requested scope" do
            @user.instance_eval do
              def scope_test_method
                role_class_name
              end
            end
            @user.auth_scope(:character, :scope_test_method).should == @user.auth_scope(:character).role_class_name
          end

          it "should allow calling a method with arguments within the requested scope" do
            suffix = rand(100)*rand(100)
            @user.instance_eval do
              def scope_test_method(suf)
                "#{role_class_name}_#{suf}"
              end
            end
            @user.auth_scope(:character, :scope_test_method, suffix).should == "#{@user.auth_scope(:character).role_class_name}_#{suffix}"
          end
        end
        
        context "when passing a block" do
          it "should allow executing a block within the requested scope" do
            @user.auth_scope(:character) do
              role_class_name
            end.should == @user.auth_scope(:character).role_class_name
          end

          it "should allow executing a block with arguments within the requested scope" do
            suffix = rand(100)*rand(100)
            @user.auth_scope(:character, suffix) do |suf|
              "#{role_class_name}_#{suf}"
            end.should == "#{@user.auth_scope(:character).role_class_name}_#{suffix}"
          end
        end
      end
    end

    describe "target_role" do
      before(:each) do
        prep_dummy
      end

      it "should require a role object or slug and a context" do
        expect { Dummy.target_role }.to raise_exception
        expect { Dummy.target_role(:role) }.to raise_exception
        expect { Dummy.target_role(:role, nil) }.to_not raise_exception
      end

      it "should accept a role object" do
        expect { Dummy.target_role(Role.new, nil) }.to_not raise_exception
      end

      it "should accept a string or symbol" do
        expect { Dummy.target_role(:role, nil) }.to_not raise_exception
        expect { Dummy.target_role('role', nil) }.to_not raise_exception
      end

      it "should allow forcing context" do
        expect { Dummy.target_role(:role, nil, true) }.to_not raise_exception
        expect { Dummy.target_role('role', nil, false) }.to_not raise_exception
      end
      
      context "when looking up a role" do
        it "should just return the role object if one is passed" do
          role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
          Dummy.target_role(role, nil).should === role
        end

        it "should use the defined role_class for the lookup" do
          role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
          Dummy.target_role(:admin, nil).should be_an_instance_of(Role)
          # TODO add another example that uses different role class
        end

        it "should use the provided slug for the lookup" do
          role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
          Dummy.target_role(:admin, nil).slug.should == 'admin'
          Dummy.target_role('admin', nil).slug.should == 'admin'
        end

        it "should normalize symbols and strings to lowercase and underscored" do
          role = Role.create(:name => 'My Cool Role', :slug => 'my_cool_role', :level => 40)
          Dummy.target_role('MyCoolRole', nil).should == role
          Dummy.target_role(:MyCoolRole, nil).should == role
        end
        
        context "within a context" do
          it "should go up the context chain to find roles" do
            context = Context.create(:name => "Test Context")
            nil_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
            Dummy.target_role(:admin, nil).should == nil_role
            Dummy.target_role(:admin, Context).should == nil_role
            Dummy.target_role(:admin, context).should == nil_role
          end

          it "should use the closest contextual match" do
            context = Context.create(:name => "Test Context")
            
            nil_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
            Dummy.target_role(:admin, nil).should == nil_role
            Dummy.target_role(:admin, Context).should == nil_role
            Dummy.target_role(:admin, context).should == nil_role
            
            class_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context')
            Dummy.target_role(:admin, nil).should == nil_role
            Dummy.target_role(:admin, Context).should == class_role
            Dummy.target_role(:admin, context).should == class_role
            
            inst_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context', :context_id => context.id)
            Dummy.target_role(:admin, nil).should == nil_role
            Dummy.target_role(:admin, Context).should == class_role
            Dummy.target_role(:admin, context).should == inst_role
          end

          context "when forcing the context" do
            it "should not go up the context chain" do
              context = Context.create(:name => "Test Context")
              
              nil_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
              Dummy.target_role(:admin, nil, true).should == nil_role
              Dummy.target_role(:admin, Context, true).should be_nil
              Dummy.target_role(:admin, context, true).should be_nil
              
              class_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context')
              Dummy.target_role(:admin, nil, true).should == nil_role
              Dummy.target_role(:admin, Context, true).should == class_role
              Dummy.target_role(:admin, context, true).should be_nil
              
              inst_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context', :context_id => context.id)
              Dummy.target_role(:admin, nil, true).should == nil_role
              Dummy.target_role(:admin, Context, true).should == class_role
              Dummy.target_role(:admin, context, true).should == inst_role
            end
          end
        end
      end
    end

    describe "target_permission" do
      before(:each) do
        prep_dummy
      end

      it "should require a permission object or slug and a context" do
        expect { Dummy.target_permission }.to raise_exception
        expect { Dummy.target_permission(:permission) }.to raise_exception
        expect { Dummy.target_permission(:permission, nil) }.to_not raise_exception
      end

      it "should accept a permission object" do
        expect { Dummy.target_permission(Permission.new, nil) }.to_not raise_exception
      end

      it "should accept a string or symbol" do
        expect { Dummy.target_permission(:permission, nil) }.to_not raise_exception
        expect { Dummy.target_permission('permission', nil) }.to_not raise_exception
      end

      it "should allow forcing context" do
        expect { Dummy.target_permission(:permission, nil, true) }.to_not raise_exception
        expect { Dummy.target_permission('permission', nil, false) }.to_not raise_exception
      end
      
      context "when looking up a permission" do
        it "should just return the permission object if one is passed" do
          permission = Permission.create(:name => 'Do Something', :slug => 'do_something')
          Dummy.target_permission(permission, nil).should === permission
        end

        it "should use the defined permission_class for the lookup" do
          permission = Permission.create(:name => 'Do Something', :slug => 'do_something')
          Dummy.target_permission(:do_something, nil).should be_an_instance_of(Permission)
          # TODO add another example that uses different permission class
        end

        it "should use the provided slug for the lookup" do
          permission = Permission.create(:name => 'Do Something', :slug => 'do_something')
          Dummy.target_permission(:do_something, nil).slug.should == 'do_something'
          Dummy.target_permission('do_something', nil).slug.should == 'do_something'
        end

        it "should normalize symbols and strings to lowercase and underscored" do
          permission = Permission.create(:name => 'My Cool Permission', :slug => 'my_cool_permission')
          Dummy.target_permission('MyCoolPermission', nil).should == permission
          Dummy.target_permission(:MyCoolPermission, nil).should == permission
        end
        
        context "within a context" do
          it "should go up the context chain to find permissions" do
            context = Context.create(:name => "Test Context")
            nil_permission = Permission.create(:name => 'Do Something', :slug => 'do_something')
            Dummy.target_permission(:do_something, nil).should == nil_permission
            Dummy.target_permission(:do_something, Context).should == nil_permission
            Dummy.target_permission(:do_something, context).should == nil_permission
          end

          it "should use the closest contextual match" do
            context = Context.create(:name => "Test Context")
            
            nil_permission = Permission.create(:name => 'Do Something', :slug => 'do_something')
            Dummy.target_permission(:do_something, nil).should == nil_permission
            Dummy.target_permission(:do_something, Context).should == nil_permission
            Dummy.target_permission(:do_something, context).should == nil_permission
            
            class_permission = Permission.create(:name => 'Do Something', :slug => 'do_something', :context_type => 'Context')
            Dummy.target_permission(:do_something, nil).should == nil_permission
            Dummy.target_permission(:do_something, Context).should == class_permission
            Dummy.target_permission(:do_something, context).should == class_permission
            
            inst_permission = Permission.create(:name => 'Do Something', :slug => 'do_something', :context_type => 'Context', :context_id => context.id)
            Dummy.target_permission(:do_something, nil).should == nil_permission
            Dummy.target_permission(:do_something, Context).should == class_permission
            Dummy.target_permission(:do_something, context).should == inst_permission
          end
          
          context "when forcing the context" do
            it "should not go up the context chain" do
              context = Context.create(:name => "Test Context")
              
              nil_permission = Permission.create(:name => 'Do Something', :slug => 'do_something')
              Dummy.target_permission(:do_something, nil, true).should == nil_permission
              Dummy.target_permission(:do_something, Context, true).should be_nil
              Dummy.target_permission(:do_something, context, true).should be_nil
              
              class_permission = Permission.create(:name => 'Do Something', :slug => 'do_something', :context_type => 'Context')
              Dummy.target_permission(:do_something, nil, true).should == nil_permission
              Dummy.target_permission(:do_something, Context, true).should == class_permission
              Dummy.target_permission(:do_something, context, true).should be_nil
              
              inst_permission = Permission.create(:name => 'Do Something', :slug => 'do_something', :context_type => 'Context', :context_id => context.id)
              Dummy.target_permission(:do_something, nil, true).should == nil_permission
              Dummy.target_permission(:do_something, Context, true).should == class_permission
              Dummy.target_permission(:do_something, context, true).should == inst_permission
            end
          end
        end
      end
    end

    describe "verify_target_context" do
      before(:each) do
        Role.acts_as_authorization_role # this is to enable Role#context, can remove/rework this once those context methods are broken out
        Permission.acts_as_authorization_permission # this is to enable Permission#context, can remove/rework this once those context methods are broken out
        prep_dummy
      end
      
      it "should require a target role or permission and a context" do
        expect { Dummy.verify_target_context }.to raise_exception
        expect { Dummy.verify_target_context(nil) }.to raise_exception
      end

      it "should accept a role or a permission as the target" do
        role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
        permission = Permission.create(:name => 'Do Something', :slug => 'do_something')
        Dummy.verify_target_context(role, nil).should be_true
        Dummy.verify_target_context(permission, nil).should be_true
      end

      it "should return false if a nil target is provided" do
        Dummy.verify_target_context(nil, nil).should be_false
      end

      it "should allow forcing context" do
        expect { Dummy.verify_target_context(nil, nil, true) }.to_not raise_exception
      end

      context "when not forcing context" do
        it "should allow nil context targets to be used within any other context" do
          context = Context.create(:name => "Test Context")
          role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
          permission = Permission.create(:name => 'Do Something', :slug => 'do_something')
          Dummy.verify_target_context(role, nil).should be_true
          Dummy.verify_target_context(role, Context).should be_true
          Dummy.verify_target_context(role, context).should be_true
          Dummy.verify_target_context(permission, nil).should be_true
          Dummy.verify_target_context(permission, Context).should be_true
          Dummy.verify_target_context(permission, context).should be_true
        end

        it "should allow class context targets to be used within the context of their class or any instances of their class" do
          context = Context.create(:name => "Test Context")
          role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context')
          permission = Permission.create(:name => 'Do Something', :slug => 'do_something', :context_type => 'Context')
          Dummy.verify_target_context(role, Context).should be_true
          Dummy.verify_target_context(role, context).should be_true
          Dummy.verify_target_context(permission, Context).should be_true
          Dummy.verify_target_context(permission, context).should be_true
        end

        it "should allow instance targets to be used within their own instance context" do
          context = Context.create(:name => "Test Context")
          role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context', :context_id => context.id)
          permission = Permission.create(:name => 'Do Something', :slug => 'do_something', :context_type => 'Context', :context_id => context.id)
          Dummy.verify_target_context(role, context).should be_true
          Dummy.verify_target_context(permission, context).should be_true
        end
        
        it "should not allow class context targets to be used within any other class or nil contexts" do
          role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context')
          permission = Permission.create(:name => 'Do Something', :slug => 'do_something', :context_type => 'Context')
          Dummy.verify_target_context(role, nil).should be_false
          Dummy.verify_target_context(role, Weapon).should be_false
          Dummy.verify_target_context(permission, nil).should be_false
          Dummy.verify_target_context(permission, Weapon).should be_false
        end
        
        it "should not allow instance context targets to be used within any other class or instance contexts or a nil context" do
          context = Context.create(:name => "Test Context")
          other_context = Context.create(:name => "Another Test Context")
          role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context', :context_id => context.id)
          permission = Permission.create(:name => 'Do Something', :slug => 'do_something', :context_type => 'Context', :context_id => context.id)
          Dummy.verify_target_context(role, nil).should be_false
          Dummy.verify_target_context(role, Context).should be_false
          Dummy.verify_target_context(role, Weapon).should be_false
          Dummy.verify_target_context(role, other_context).should be_false
          Dummy.verify_target_context(permission, nil).should be_false
          Dummy.verify_target_context(permission, Context).should be_false
          Dummy.verify_target_context(permission, Weapon).should be_false
          Dummy.verify_target_context(permission, other_context).should be_false
        end
      end

      context "when forcing context" do
        it "should only allow the target to be used within the provided context" do
          context = Context.create(:name => "Test Context")
          nil_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
          class_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context')
          inst_role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100, :context_type => 'Context', :context_id => context.id)
          Dummy.verify_target_context(nil_role, nil, true).should be_true
          Dummy.verify_target_context(nil_role, Context, true).should be_false
          Dummy.verify_target_context(nil_role, context, true).should be_false
          Dummy.verify_target_context(class_role, nil, true).should be_false
          Dummy.verify_target_context(class_role, Context, true).should be_true
          Dummy.verify_target_context(class_role, context, true).should be_false
          Dummy.verify_target_context(inst_role, nil, true).should be_false
          Dummy.verify_target_context(inst_role, Context, true).should be_false
          Dummy.verify_target_context(inst_role, context, true).should be_true
          nil_permission = Permission.create(:name => 'Do Something', :slug => 'do_something')
          class_permission = Permission.create(:name => 'Do Something', :slug => 'do_something', :context_type => 'Context')
          inst_permission = Permission.create(:name => 'Do Something', :slug => 'do_something', :context_type => 'Context', :context_id => context.id)
          Dummy.verify_target_context(nil_permission, nil, true).should be_true
          Dummy.verify_target_context(nil_permission, Context, true).should be_false
          Dummy.verify_target_context(nil_permission, context, true).should be_false
          Dummy.verify_target_context(class_permission, nil, true).should be_false
          Dummy.verify_target_context(class_permission, Context, true).should be_true
          Dummy.verify_target_context(class_permission, context, true).should be_false
          Dummy.verify_target_context(inst_permission, nil, true).should be_false
          Dummy.verify_target_context(inst_permission, Context, true).should be_false
          Dummy.verify_target_context(inst_permission, context, true).should be_true
        end
      end
    end
  end

end
