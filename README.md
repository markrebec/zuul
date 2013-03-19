# Zuul
Contextual Authorization and Access Control for ActiveRecord and ActionController respectively, along with a few handy extras (like generators) for Rails. The name is a reference to the film [Ghostbusters](http://en.wikipedia.org/wiki/Ghostbusters) (1984), in which an ancient Sumerian deity called [Zuul](http://www.gbfans.com/wiki/Zuul), also known as The Gatekeeper, possesses the character Dana Barrett.

### Zuul is undergoing some changes!
[Wes Gibbs](https://github.com/wgibbs) has been kind enough to transfer maintenance of the gem to myself ([Mark Rebec](https://github.com/markrebec)), and in turn I'm taking some time to revamp and upate Zuul to provide some new features and make everything compatible with the latest versions of ActiveRecord and ActionController.

The version is being bumped to `0.2.0` to start, and version history is being maintained so we don't break any existing implementations. This also allows continued use, maintenance and forking of any previous versions of the gem if anyone should prefer to use a version prior to the switchover.

I can't thank Wes enough for allowing me to take over Zuul, rather than introducing yet-another-competing-access-control-gem for everyone to sort through!

## Features
Zuul provides an extremely flexible authorization solution for ActiveRecord wherein roles and (optionally) permissions can be assigned within various contexts, along with an equally robust access control DSL for ActionController and helpers for your views. It can be used with virtually any authentication system (I highly recommend [devise](http://github.com/platformatec/devise) if you haven't chosen one yet), and it provides the following features:

* **Completely Customizable:** Allows configuration of everything - models used as authorization objects, how the context chain behaves, how access control rules are evaluated, and much more.
* **Modular:** You can use just the ActiveRecord authorization system and completely ignore the ActionController DSL, or even configure the controller DSL to use your own methods (allowing you to decouple it from the authorization models completely).
* **Optional Permissions:** Use of permissions is completely optional. When disabled, modules won't even get included, preventing permissions methods from littering your models. When enabled, permissions can be assigned to roles or directly to individual subjects if you require that level of control.
* **Authorization Models:** Can be used with your existing models, and doesn't require any database modifications for subjects (like users) or resource contexts (like blog posts). You also have the choice of generating new role and/or permissions models, or utilizing existing models as those roles and permissions - for example, if you were building a game and you wanted your `Level` and `Achievement` models to behave as "Roles" and "Permissions" for a `Character`, which would allow/deny that character access to various `Dungeon` objects.
* **Contextual:** Allows creating and assigning abilities within a provided context - either globally, at the class level, or at the object level - and contexts can be mixed-and-matched (within the context chain). *While contexts are currently required for Zuul to work, you can "ignore" them by simply creating/managing everything at the global level, and there are plans to look into making contexts optional in future versions.*
* **Context Chain:** There is a built-in "context chain" that is enforced when working with roles and permissions. This allows for both a high level of flexibility (i.e. roles can be applied within child contexts) and finer level of control (i.e. looking up a specific role within a specific context and not traversing up the chain), and can be as simple or complex as you want.
* **Scoping:** All authorization methods are scoped, which allows the same model to act as an authorization subject for multiple scopes (each with it's own role/permission models).
* **Controller ACL:** Provides a flexible access control DSL for your controllers that gives the ability to allow or deny access to controller actions and resources based on roles or permissions, and provides a few helper methods and pseudo roles for logged in/out.
* **Helpers:** There are a few helpers included, like `for_role`, which allow you to execute blocks or display templates based on whether or not a subject possesses the specified role/permission, with optional fallback blocks if not.

## Getting Started
Zuul &gt;= 0.2.0 works with Rails &gt;= 3.1 (probably older versions too, but it hasn't ben tested yet). To use it, ensure you're using rubygems.org as a source (if you don't know what that means, you probably are) and add this to your gemfile:

    gem `zuul`

Then run bundler to install it.

In order to use the core authorization functionality, you'll need to setup subjects and roles. Permissions are enabled in the default configuration, so if you don't specify otherwise you'll have to setup the permissions model as well. Each authorization model type has it's own default, but those can be overridden in the global initializer config, or they can be specified per-model as you're setting up authorization models.

####Authorization Subjects
An authorization subject is the object to which you grant roles and permissions, usually a user. In order to use Zuul, you'll need to setup at least one subject model. The default model is `User`.

####Authorization Roles
Authorization roles are the roles that can be assigned to the subject mentioned above, and then used to allow or deny access to various resources. Zuul requires at least one role model. The default model is `Role`.

####Authorization Permissions
Authorization permissions are optional, and allow finer grained control over which subjects have access to which resources. Permissions can be assigned to roles (which are in turn assigned to subjects), or they can be assigned directly to subjects themselves. They require that the model be setup in order to be used by roles or subjects, and the default model is `Permission`.

####Authorization Resources (Contexts)
Authorization resources, or contexts, behave as both the resources that are being accessed by a subject, as well as (optionally) a context within which roles or permissions can be created and assigned. When combined with Zuul's "context chain," this allows you to define or assign roles for specific models or even specific instances of those models. No setup is required to use a model as a resource or context, but there is some optional configuration that provides the model directly with methods to authorize against roles and permissions. Resource/context models are not required, and there are no configured defaults.

### Generating Authorization Models
It's likely you already have a `User` model (or equivalent), especially if you've already got some form of authentication setup in your app. However, you probably don't yet have any role or permission models setup unless you're transitioning from another authorization solution. Either way, you can use the provided generators to create new models or to configure existing models as authorization objects. The generators work just like the normal model generators (with a few additions) and will either create the models and migrations for you if they don't exist, or modify your models and create any necessary migrations if they do.

####Generate an authorization subject model
To generate a subject model, you can use the `zuul:subject` generator, and pass it options just like you would if you were creating a normal model. The generator is smart enough to know whether your model already exists, and acts accordingly.

    rails generate zuul:subject User email:string password:string

The extra field names are optional and are only parsed if you're creating the model for the first time. Only the name of the model is required.

The above will create a standard migration at `/db/migrate/TIMESTAMP_create_users.rb` if the model did not exist (since no extra fields are required on a subject model) and will create the model itself in `/app/models/user.rb` if it does not exist. It will also add the default `acts_as_authorization_subject` configuration to the model. Using the above example to create a new `User` model, the generated model looks like below. *Note: Saying "no extra fields are required" is not entirely accurate. An integer primary key **is** required for all subjects.*

    class User < ActiveRecord::Base
      # Setup authorization for your subject model
      acts_as_authorization_subject
      attr_accessible :email, :password
    end

If you are modifying an existing model, any optional fields passed into the generator are ignored, and the only change the generator makes is to insert the following lines into your model:
      
    # Setup authorization for your subject model
    acts_as_authorization_subject

There are a number of configuration options for `acts_as_authorization_subject` outlined elsewhere in this document, but this is enough to get us going. The default configuration, however, will be looking for a `Role` model and a `Permission` model, so we should create those next.

####Generate an authorization role model
You can use the `zuul:role` generator for roles, and like the subject generator, you can pass in optional fields. There are four required fields, which are automatically added to your model and migrations by the generator - `slug`, `level`, `context_type` and `context_id` - and you can specify any additional fields you'd like, such as a name or description.

    rails generate zuul:role Role name:string

If the `Role` model doesn't exist, the above command will create a migration in `/db/migrate/TIMESTAMP_zuul_role_create_roles.rb` to create the table, and create the model in `/app/models/role.rb`. The model will also be configured with the `acts_as_authorization_role` method.  The example above would generate the following model:

    class Role < ActiveRecord::Base
      # Setup authorization for your role model
      acts_as_authorization_role
      attr_accessible :name
    end

If you are using the generator to configure an existing model, a migration will be created at `/db/migrate/TIMESTAMP_add_zuul_role_to_roles.rb` to add the required authorization fields. The model will also be configured with the `acts_as_authorization_role` method, and the following lines will be inserted into your model:
      
    # Setup authorization for your role model
    acts_as_authorization_role

Like the other authorization object types, there are lots of configuration options for `acts_as_authorization_role` but we're just using defaults here.

####Generate an authorization permission model
Generating a permission model is just like generating a role model, with a few slight differences.  There are three required fields for permissions, which are created automatically by the generator - `slug`, `context_type`, `context_id` - and you may specify any others you'd like.

    rails generate zuul:permission Permission

If the `Permission` model doesn't exist, the above command will create a migration in `/db/migrate/TIMESTAMP_zuul_permission_create_permissions.rb` to create the table, and create the model in `/app/models/permission.rb`. The model will also be configured with the `acts_as_authorization_permission` method.  The example above, which doesn't specify any additional fields for the model, would generate the following model:

    class Permission < ActiveRecord::Base
      # Setup authorization for your permission model
      acts_as_authorization_permission
    end

If you are using the generator to configure an existing model, a migration will be created at `/db/migrate/TIMESTAMP_add_zuul_permission_to_permissions.rb` to add the required authorization fields. The model will also be configured with the `acts_as_authorization_permission` method, and the following lines will be inserted into your model:

    # Setup authorization for your permission model
    acts_as_authorization_permission

Like the other authorization object types, there are lots of configuration options for `acts_as_authorization_permission` but we're just using defaults here.

####Generate authorization association models
The last thing you'll need to generate are the association models that link roles to subjects, and link permissions to roles and subjects (if you're using permissions). These generators are very simple and only take two arguments, which are the names of the models you're associating, and there are configured defaults if you don't pass any arguments. They are able to accept additional optional field arguments (like all the other generators) if you'd like to add extra fields to the models for any reason, and will also act accordingly depending on whether your models and migrations already exist or not.

For roles and subjects:

    rails generate zuul:role_subject Role User

For permissions and roles:

    rails generate zuul:permission_role Permission Role

For permissions and subjects:

    rails generate zuul:permission_subject Permission User

These commands will generate models (if they don't exist) and migrations for the `RoleUser`, `PermissionRole` and `PermissionUser` models.  As with everywhere else in Zuul, the model names are based on the default ActiveRecord behavior of sorting alphabetically, but this can all be configured to use custom model and table names for everything.

###Creating and using authorization abilities
Once you've run all the generators, you'll need to run the generated migrations with `rake db:migrate` to update your database, and then it's time to start creating roles and permissions (and subjects if you don't have any).

To create a role, all you need to do is use the `Role.create` method and supply the required fields (`slug` and `level`). Roles can be created within a specific context, but that's covered elsewhere in this document.

    admin = Role.create(:slug => 'admin', :level => 100)
    moderator = Role.create(:slug => 'moderator', :level => 80)
    vip = Role.create(:slug => 'vip', :level => 50)
    banned = Role.create(:slug => 'banned', :level => 1)

Assuming you already have users in your users table, you can now assign these roles to them:

    user = User.find(1)
    user.assign_role(:admin)        # you can pass a symbol
    user.assign_role('moderator')   # or a string
    user.assign_role(vip)           # or the role object itself

And once you've got a user with roles assigned to them, you can check if they possess various roles:

    user = User.find(1)
    user.has_role?(:admin)
    user.has_role?('vip')
    user.has_role_or_higher?('moderator')   # has_role_or_higher? will also return true if the user possesses any roles with a higher level than the one provided

Creating and assigning permissions is similar to roles, except the `slug` is the only required field:

    view = Permission.create(:slug => 'view')
    create = Permission.create(:slug => 'create')
    edit = Permission.create(:slug => 'edit')
    destroy = Permission.create(:slug => 'destroy')

And you can assign those permissions to roles (which can in turn be assigned to subjects), or you can assign those permissions directly to a subject:

    role = Role.find_by_slug('admin')
    role.assign_permission(:create)   # assigns the :create permission to the :admin role, granting any user with that role the :create permission
    
    user = User.find(1)
    user.assign_permission('view')    # assigns the :view permission directly to the user

When checking whether a subject possesses a permission, both their individual permissions and those belonging to their assigned roles are evaluated:

    user = User.find(1)
    user.has_permission?(:edit)  # true if the user has :edit assigned directly OR if the user is assigned a role which is in turn assigned the :edit permission

###Setup access control for your controllers
The first step in setting up your controllers is to ensure you have a `current_user` method available. This is provided by many authorization solutions (such as [devise](https://github.com/plataformatec/devise)), but if you don't already have one, you'll need to set one up. All the method needs to do is return a user object or `nil` if there is no user (i.e. not logged in). You can also configure a method other than `current_user` either globally or per-filter.

Once you've got your `current_user` method in place, you can start to implement the `access_control` filters in your controllers. Here are a couple examples that all do the same thing - allow :admin roles access to :create, :destroy, :edit, :new, :update, and allow :user roles access to :index.

    class StrictExampleController < ApplicationController
      access_control do
        roles :admin do
          allow :create, :destroy, :edit, :index, :new, :update
        end
        
        roles :user do
          allow :index
        end
      end
    end
    
    class StrictExampleController < ApplicationController
      access_control do
        roles :admin do
          allow :create, :destroy, :edit, :new, :update
        end

        roles :admin, :user do
          allow :index
        end
      end
    end
    
    class StrictExampleController < ApplicationController
      access_control do
        actions :index do
          allow_roles :admin, :user
        end
        
        actions :create, :destroy, :edit, :new, :update do
          allow_roles :admin
        end
      end
    end

You can of course check for permissions as well. This example denies any logged out users (with the `logged_out` pseudo-role) and any users with the :banned permission from all actions (using the `all_actions` helper method).

    class BannedExampleController < ApplicationController
      access_control do
        roles logged_out do
          deny all_actions
        end

        permissions :banned do
          deny all_actions
        end
      end
    end

There are a number of configuration options and additional DSL methods available for the `access_control` filters, and multiple filters can even be chained together.

**TODO: Add notes about default handling of 'access denied' and using rescue_from in controllers**




## Configuration

## Authorization Models

## The Context Chain

## Access Control DSL

## Contributing

##TODO
* fill out readme + documentation
* create generators for joining models
* write specs for generators
* abstract out ActiveRecord, create ORM layer to allow other datasources
* create a logger for the ACL DSL stuff and clean up the logging there
* add some built-in defaults for handling access denied errors and rendering a default template and/or flash message
* write specs for all the controller mixins
* clean up errors/exceptions a bit more
* i18n for messaging, errors, templates, etc.

## Copyright/License
