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

**Note:** There are no inherent abilities granted by assigning any roles or permissions to a subject. Just because you define an `:admin` role and assign it to a user, that doesn't mean they can do anything special. It's up to you to check whether a subject possesses those roles and permissions in your code and act accordingly.

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

Once you've got your `current_user` method in place, you can start to implement the `access_control` filters in your controllers. Here are a couple examples that all do the same thing - allow :admin roles access to :create, :destroy, :edit, :index, :new and :update, and allow :user roles access only to :index.

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

By default, an `AccessDenied` exception is raised when a subject is denied access. You can customize this behavior in a few ways to either redirect, render or do essentially whatever you want.

The first option is to use `rescue_from` in your controllers to catch the exception. In most cases you can define the `rescue_from` block once on your `ApplicationController` and it will be inherited by all child controllers. If you want to do different things in different controllers, you can use `rescue_from` directly with those controllers. Here's a basic example using `ApplicationController`:

    class ApplicationController < ActionController::Base
      rescue_from Zuul::Exceptions::AccessDenied, :with => :access_denied   # the access_denied method is defined below. you can also just pass a block instead of :with => :method

      def access_denied
        # you can use this method to redirect or render an error template (or do whatever you want)
      end
    end

    class MyExampleController < ApplicationController
      access_control do
        # add your rules here
      end
    end

The other option, instead of using `rescue_from`, is to set the `:mode` config option to `:quiet` for the `access_control` block, which will surpress the exception and allow you to use the `authorized?` method to check the results yourself:

    class MyExampleController < ApplicationController
      access_control :mode => :quiet do
        # add your rules here
      end

      before_filter do |controller|
        # you can add a before_filter and check controller.authorized? here, then redirect or render an error
        do_something unless controller.authorized?
      end

      def index
        # or you can use authorized? directly within your controller actions to decide what to do per-action
        do_something_specific unless authorized?
      end
    end

##Configuration
Zuul is extremely configurable, and there are options to control just about everything at the global level and ways to override just about everything in specific authorization objects or `access_control` blocks.  For example, you may have the use of permissions configured globally, but want to disable them for a secondary, special subject+role scope that you're setting up. Or you may want the global default behavior of your access control blocks to be `:allow` (less strict), but then define `access_control :default => :deny` for stricter matching on more sensitive controllers.

In order to configure Zuul and set your own global defaults, you can create an initializer in `/config/initializers/zuul.rb`:

    Zuul.configure do |config|
      # configuration options go here
      config.with_permissions = false # defaults to true
      config.subject_method = :logged_in_user # defaults to :current_user
      # etc...
    end

Whatever you set here will override the Zuul global defaults, and your values will be used as defautls by any authorization models or access control blocks you define (unless you override them).  This allows you to override common defaults like `:with_permissions` without having to do so over and over again in your models and controllers.

Take a look at the authorization models and access control DSL documentation for more information on what config options can be overridden when defining them.

###Global configuration options
**TODO: add a table with all the config options and what they do**

##Authorization Models
Authorization models are any of the subject, role, permission or resource/context models that are used by the authorization system (take a look at the Getting Started section for a brief explanation of each). They are configured using the `acts_as_authorization_*` methods - such as `acts_as_authorization_subject` for authorization subjects.

When a model "acts as an authorization object," it inherits some behaviors specific to the type of object it's acting as.  For example with subjects, this provides them the ability to have roles and permissions assigned to them, or check if they `has_role?(:admin)`. Roles and permissions are a bit simpler, and are provided with some methods to help them behave as what they are, check them against subjects, etc. And finally resources/contexts, if you choose to define them, are given some shortcut methods like `allowed?(user, role)` which essentially are just wrappers to check whether the user possesses the role for the provided resource (within the provided context).

###Subjects
Zuul authorization subjects provide a few methods to make it easy to assign, remove and verify roles and permissions.

**TODO: add a table with a list of methods like has_role?, assign_role, unassign_role, etc.**

###Roles
Authorization roles are provided with methods to assign, remove and verify permissions against the role. This in turn grants those permissions to any subjects who possess the role.

**TODO: add a table with a list of methods like has_permission?, assign_permission, etc.**

###Permissions
Authorization permissions do not have any useful public methods available, since all the management is handled against the subjects or roles to which they are assigned. They mostly just have a few associations and internal methods defined to facilitate their use by the other authorization objects.

###Resources & Contexts
Defining resources (also used as contexts) is not required. You can use subjects, roles and permissions to authorize against any model without having to modify the resource model in any way. However, you have the option of configuring your resource models to `acts_as_authorization_context`, which will provide a few shortcut methods for you (which are all just wrappers for the methods defined on the subject being authorized).

**TODO: add a table with the resource/context methods - allowed?, allowed_to?**

###Configuring class names
Zuul comes with some default class names that are used when generating and configuring authorization models, but you can use any class names you'd like. These can be defined globally (see the Configuration section of this readme) to DRY up your code, or when setting up a model to `acts_as_authorization_*`. If you set them up globally they'll be used in place of the defaults unless you override them. 

When configuring an authorization model, you don't need to provide the name of the model you're configuring. So if you're configuring a `Soldier` as an authorization subject, you don't need to provide the subject class name. You also don't need to worry about table names or foreign keys, as Zuul will ask your models for that information rather than trying to inflect the provided class names.

Here is an example using some custom classes:

    # this is our subject, a chef who will be assigned cuisines
    class Chef < ActiveRecord::Base
      # you can set classes as strings, symbols or actuall class constants
      acts_as_authorization_subject :role_class => :cuisine, :permission_class => Ingredient
    end

    # cuisine might be things like 'seafood', 'bbq', etc.
    class Cuisine < ActiveRecord::Base
      acts_as_authorization_role :subject_class => :chef, :permission_class => :ingredient
    end

    # a cuisine would probably have ingredients assigned to it - like 'fish' and 'scallops' for seafood
    # but a chef might also have an ingredient like 'fish' in their repertoire without specializing in seafood
    class Ingredient < ActiveRecord::Base
      acts_as_authorization_permission :subject_class => :chef, :role_class => :cuisine
    end

If you only provide the core class names, as above, Zuul will fill in the blanks for the association models automatically. So in the above example, chefs and cuisines will be linked together using the `ChefCuisine` model.

You can override each association model class name as well if you need to. Let's say you wanted to link `Chef` and `Cuisine` with a model called `Specialty`. Just provide the `:role_subject_class` as well:

    class Chef < ActiveRecord::Base
      acts_as_authorization_subject :role_class => :cuisine, :role_subject_class => :specialty, :permission_class => :ingredient
    end

    class Cuisine < ActiveRecord::Base
      acts_as_authorization_subject :subject_class => :chef, :role_subject_class => :specialty, :permission_class => :ingredient
    end

The config options for the three association classes are `:role_subject_class`, `:permission_role_class` and `:permission_subject_class`.

###Scoping
###The Context Chain

##Access Control DSL

##Contributing

##TODO
* fill out readme + documentation
* add some built-in defaults for handling access denied errors and rendering a default template and/or flash message
* clean up errors/exceptions a bit more
* i18n for messaging, errors, templates, etc.
* create a logger for the ACL DSL stuff and clean up the logging there
* write specs for generators
* write specs for all the controller mixins
* abstract out ActiveRecord, create ORM layer to allow other datasources

##Copyright/License
