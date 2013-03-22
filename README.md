# Zuul
Contextual Authorization and Access Control for ActiveRecord and ActionController respectively, along with a few handy extras (like easy to use generators) for Rails.

#### Zuul is undergoing some changes
[Wes Gibbs](https://github.com/wgibbs) has been kind enough to transfer maintenance of the gem to myself ([Mark Rebec](https://github.com/markrebec)), and in turn I'm taking some time to update zuul to provide some new features and make everything compatible with the latest versions of ActiveRecord and ActionController.

The version is being bumped to `0.2.0` and version history is being maintained to allow maintenance and forking of any `0.1.x` versions of the gem.

I can't thank Wes enough for allowing me to take over zuul, rather than introducing yet-another-competing-access-control-gem for everyone to sort through!

## Features
Zuul provides an extremely flexible authorization solution for ActiveRecord wherein roles and (optionally) permissions can be assigned within various contexts, along with an equally robust access control DSL for ActionController and helpers for your views. It can be used with virtually any authentication system (I highly recommend [devise](http://github.com/platformatec/devise) if you haven't chosen one yet), and it provides the following features:

* **Completely Customizable:** Allows configuration of everything - models used as authorization objects, how the context chain behaves, how access control rules are evaluated, and much more.
* **Modular:** You can use just the ActiveRecord authorization system and completely ignore the ActionController DSL, or even configure the controller DSL to use your own methods (allowing you to decouple it from the authorization models completely).
* **Optional Permissions:** Use of permissions is completely optional. When disabled, modules won't even get included, preventing permissions methods from littering your models. When enabled, permissions can be assigned to roles or directly to individual subjects if you require that level of control.
* **Authorization Models:** Can be used with your existing models, and doesn't require any database modifications for subjects (like users) or resource contexts (like blog posts). You also have the choice of generating new role and permissions models, or utilizing existing models as those roles and permissions - for example, if you were building a game and you wanted your `Level` and `Skill` models to behave as "Roles" and "Permissions" for a `Character`, which would allow/deny that character access to various dungeons or weapons.
* **Contextual:** Allows creating and assigning abilities within a provided context - either globally, at the class level, or at the object level - and contexts can be mixed-and-matched (within the context chain). *While contexts are currently required for zuul to work, you can "ignore" them by simply creating/managing everything at the global level, and there are plans to look into making contexts optional in future versions.*
* **Context Chain:** There is a built-in "context chain" that is enforced when working with roles and permissions. This allows for both a high level of flexibility (i.e. roles can be applied within child contexts) and finer level of control (i.e. looking up a specific role within a specific context and not traversing up the chain), and can be as simple or complex as you want.
* **Named Scoping:** All authorization methods are scoped, which allows the same model to act as an authorization object for multiple scopes (each with it's own role/permission models).
* **Controller ACL:** Provides a flexible access control DSL for your controllers that gives the ability to allow or deny access to controller actions and resources based on roles or permissions, and provides a few helper methods and pseudo roles for logged in/out.
* **Helpers:** There are a few helpers included, like `for_role`, which allow you to execute blocks or display templates based on whether or not a subject possesses the specified role/permission, with optional fallback blocks if not.

## Getting Started
Zuul &gt;= 0.2.0 works with Rails &gt;= 3.1 (probably older versions too, but it hasn't ben tested yet). To use it, ensure you're using rubygems.org as a source (if you don't know what that means, you probably are) and add this to your gemfile:

    gem `zuul`

Then run bundler to install it.

In order to use the core authorization functionality, you'll need to setup subjects and roles. Permissions are enabled in the default configuration, so if you don't specify otherwise you'll have to setup the permissions model as well. Each authorization model type has it's own default, but those can be overridden in the global initializer config, or they can be specified per-model as you're setting up authorization models.

####Authorization Subjects
An authorization subject is the object to which you grant roles and permissions, usually a user. In order to use zuul, you'll need to setup at least one subject model. The default model is `User`.

####Authorization Roles
Authorization roles are the roles that can be assigned to the subject mentioned above, and then used to allow or deny access to various resources. Zuul requires at least one role model. The default model is `Role`.

####Authorization Permissions
Authorization permissions are optional, and allow finer grained control over which subjects have access to which resources. Permissions can be assigned to roles (which are in turn assigned to subjects), or they can be assigned directly to subjects themselves. They require that the model be setup in order to be used by roles or subjects, and the default model is `Permission`.

####Authorization Resources (Contexts)
Authorization resources, or contexts, behave as both the resources that are being accessed by a subject, as well as (optionally) a context within which roles or permissions can be created and assigned. When combined with zuul's "context chain," this allows you to define or assign roles for specific models or even specific instances of those models. No setup is required to use a model as a resource or context, but there is some optional configuration that provides the model directly with methods to authorize against roles and permissions. Resource/context models are not required, and there are no configured defaults.

### Generating Authorization Models
It's likely you already have a `User` model (or equivalent), especially if you've already got some form of authentication setup in your app. However, you probably don't yet have any role or permission models setup unless you're transitioning from another authorization solution. Either way, you can use the provided generators to create new models or to configure existing models as authorization objects. The generators work just like the normal model generators (with a few additions) and will either create the models and migrations for you if they don't exist, or modify your models and create any necessary migrations if they do.

####Generate an authorization subject model
To generate a subject model, you can use the `zuul:subject` generator, and pass it options just like you would if you were creating a normal model. The generator is smart enough to know whether your model already exists, and acts accordingly.

    rails generate zuul:subject User email:string password:string

The extra field names are optional and are only parsed if you're creating the model for the first time. Only the name of the model is required.

The above will create a standard migration at `/db/migrate/TIMESTAMP_create_users.rb` if the model did not exist and will create the model itself in `/app/models/user.rb` if it does not exist. It will then add the default `acts_as_authorization_subject` configuration to the model. Using the above example to create a new `User` model, the generated model looks like below.

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

These commands will generate models (if they don't exist) and migrations for the `RoleUser`, `PermissionRole` and `PermissionUser` models.  As with everywhere else in zuul, the model names are based on the default ActiveRecord behavior of sorting alphabetically, but this can all be configured to use custom model and table names for everything.

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

In order to configure zuul and set your own global defaults, you can create an initializer in `/config/initializers/zuul.rb`:

    Zuul.configure do |config|
      # configuration options go here
      config.with_permissions = false # defaults to true
      config.subject_method = :logged_in_user # defaults to :current_user
      # etc...
    end

Whatever you set here will override the zuul global defaults, and your values will be used as defautls by any authorization models or access control blocks you define (unless you override them).  This allows you to override common defaults like `:with_permissions` without having to do so over and over again in your models and controllers.

Take a look at the authorization models and access control DSL documentation for more information on what config options can be overridden when defining them.

###Global configuration options
<table>
  <tr>
    <th>Setting</th>
    <th>Valid Options</th>
    <th>Description</th>
  </tr>
  <tr>
    <td><code>subject_class</code></td>
    <td>A string, symbol or class constant. Defaults to <code>:user</code></td>
    <td>The specified class is used as the default subject class when defining authorization models. It can be overridden when defining the authorization models.</td>
  </tr>
  <tr>
    <td><code>role_class</code></td>
    <td>A string, symbol or class constant. Defaults to <code>:role</code></td>
    <td>The specified class is used as the default role class when defining authorization models. It can be overridden when defining the authorization models.</td>
  </tr>
  <tr>
    <td><code>permission_class</code></td>
    <td>A string, symbol or class constant. Defaults to <code>:permission</code></td>
    <td>The specified class is used as the default permission class when defining authorization models. It can be overridden when defining the authorization models.</td>
  </tr>
  <tr>
    <td><code>role_subject_class</code></td>
    <td>A string, symbol or class constant. Defaults to <code>:role_user</code></td>
    <td>The specified class is used as the default association class for roles and subjects when defining authorization models. It can be overridden when defining the authorization models.</td>
  </tr>
  <tr>
    <td><code>permission_role_class</code></td>
    <td>A string, symbol or class constant. Defaults to <code>:permission_role</code></td>
    <td>The specified class is used as the default association class for permissions and roles when defining authorization models. It can be overridden when defining the authorization models.</td>
  </tr>
  <tr>
    <td><code>permission_subject_class</code></td>
    <td>A string, symbol or class constant. Defaults to <code>:permission_user</code></td>
    <td>The specified class is used as the default association class for permissions and subjects when defining authorization models. It can be overridden when defining the authorization models.</td>
  </tr>
  <tr>
    <td><code>acl_default</code></td>
    <td><code>:allow</code> or <code>:deny</code>. Defaults to <code>:deny</code></td>
    <td>The default matching behavior used by the controller ACL filters. Can be overridden when defining access control filters.</td>
  </tr>
  <tr>
    <td><code>acl_mode</code></td>
    <td><code>:raise</code> or <code>:quiet</code>. Defaults to <code>:raise</code></td>
    <td>Dictates how the ACL filters will handle access denied errors. If set to <code>:raise</code> an exception will be raised. If set to <code>:quiet</code> no exception will be raised and you can use the <code>authorized?</code> method to check for the result. Can be overridden when defining access control filters.</td>
  </tr>
  <tr>
    <td><code>acl_collect_results</code></td>
    <td><code>true</code> or <code>false</code>. Defaults to <code>false</code></td>
    <td>Whether or not chained ACL filters will collect their results or not by default. If set to <code>true</code> each filter will analyze it's rules and pass along a single result of <code>allow</code> or <code>deny</code. If set to <code>false</code> the individual rule results will be passed along and analyzed with the next set of rules. Can be overridden when defining access control filters.</td>
  </tr>
  <tr>
    <td><code>subject_method</code></td>
    <td>A string or symbol. Defaults to <code>:current_user</code></td>
    <td>The default method used by the ACL filters to determine which subject to authorize against the defined rules. Can be overridden when defining access control filters.</td>
  </tr>
  <tr>
    <td><code>force_context</code></td>
    <td><code>true</code> or <code>false</code>. Defaults to <code>false</code></td>
    <td>Whether or not to force provided contexts for authorization operations. This applies to the authorization models and the access control filters, and can be overridden when defining either one.</td>
  </tr>
  <tr>
    <td><code>scope</code></td>
    <td>A symbol. Defaults to <code>:default</code></td>
    <td>The default scope to use for authorization options. This applies to the authorization models and the access control filters, and can be overridden when defining either one.</td>
  </tr>
  <tr>
    <td><code>with_permissions</code></td>
    <td><code>true</code> or <code>false</code>. Defaults to <code>true</code></td>
    <td>Enable or disable the use of permissions with your authorization models. Can be overridden when defining the authorization models.</td>
  </tr>
</table>

##Authorization Models
Authorization models are any of the subject, role, permission or resource/context models that are used by the authorization system (take a look at the Getting Started section for a brief explanation of each). They are configured using the `acts_as_authorization_*` methods - such as `acts_as_authorization_subject` for authorization subjects.

When a model "acts as an authorization object," it inherits some behaviors specific to the type of object it's emulating.  For example with subjects, this provides them the ability to have roles and permissions assigned to them, or check if they `has_role?(:admin)`. Roles and permissions are a bit simpler, and are provided with some methods to help them behave as what they are, check them against subjects, etc. And finally resources/contexts, if you choose to define them, are given some shortcut methods like `allowed?(user, role)` which essentially are just wrappers to check whether the user possesses the role for the provided resource (within the provided context).

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

When configuring an authorization model, you don't need to provide the name of the model you're configuring. So if you're configuring a `Soldier` as an authorization subject, you don't need to provide the subject class name. You also don't need to worry about table names or foreign keys, as zuul will ask your models for that information rather than trying to inflect the provided class names.

Here is an example using some custom classes:

    # this is our subject, a chef who will be assigned cuisines
    class Chef < ActiveRecord::Base
      # you can set classes as strings, symbols or actual class constants
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

If you only provide the core class names, as above, zuul will fill in the blanks for the association models automatically. So in the above example, chefs and cuisines will be linked together using the `ChefCuisine` model.

You can override each association model class name as well if you need to. Let's say you wanted to link `Chef` and `Cuisine` with a model called `Specialty`. Just provide the `:role_subject_class` as well:

    class Chef < ActiveRecord::Base
      acts_as_authorization_subject :role_class => :cuisine, :role_subject_class => :specialty, :permission_class => :ingredient
    end

    class Cuisine < ActiveRecord::Base
      acts_as_authorization_subject :subject_class => :chef, :role_subject_class => :specialty, :permission_class => :ingredient
    end

The config options for the three association classes are `:role_subject_class`, `:permission_role_class` and `:permission_subject_class`.

###The Context Chain
All operations involving roles and permissions within zuul utilize "the context chain," which dictates what roles and permissions are allowed to be used within what context. There are three types of contexts - global, class level and object/instance level - and they are organized in a hierarchy which defines how they may be used within the chain. Basically they cascade in order, from global to class to instance level:

Roles and permissions defined within the global context may also be assigned at the class or instance level. The global context is sometimes also referred to as a 'nil context', since it is defined by leaving the context data blank.

Those defined at the class level may only be used within a class level context that matches it's own, or any instance level contexts with a matching class. The class level context is defined by providing the class name to which the context applies.  For example, you might assign the role `:admin` to a subject within a context of `BlogPost`, and use that to allow subjects to have admin access to all blog posts.

If defined at the instance level, the role or permission may only be used within that context. The instance level context is defined by providing the class name and the primary key (id) of the record to which the context applies. This allows you to assign the permission `:edit_thread` to a role or individual subject within the context type of `DiscussionForum` and the id of a specific forum, which you can then use to allow editing of threads within just the specified forum.

When dealing with contexts in zuul, one important thing to keep in mind is that there are **two types of contexts** in action. There is the context within wich a role or permissions is **defined** and the context within which a role or permission is **assigned**, and the former generally dictates the latter. This means that any role or permission defined within a context (including the nil/global context) may only be used within it's own context or other valid contexts further down the chain.

So for example, if you **define** the role `:admin` within a global context, you may **assign** that role to subjects within any context. However, if you **define** that `:admin` role within the context of `DiscussionForum` you may not **assign** that role within a global context or any other class context, but you may assign it within the same context or within an instance level context for an instance of that same class.

It is also important to understand that zuul will prefer the closest contextual match to the one provided, and uses the context chain both for the lookup of the role or permission and when checking whether it is assigned to a subject. This mostly comes into play when you want to force the use of a particular context and not bubble up the context chain.

**But why would you want to define and assign a role in two separate contexts, or even define contexts in the first place?** It depends, you may not need contexts at all. If that's the case you can just use the default global context without even thinking about it (just don't specify contexts), and you can probably skip this section entirely. However, you may want to define and assign roles separately for specific types of resources, or even define a single set of roles at the global level and then assign them contextually. 

Maybe you want to define one `:moderator` role to be used for your discussion forums and a separate `:moderator` role only for use with a video submissions system. You could create two separate roles, both with the `moderator` slug but each defined within their own context, and then you could assign those to the users who are moderators of the appropriate section of your site. Alternately you might want to define a single global `:moderator` role, and then just assign that role to various subjects within the appropriate context (discussion forums, video submissions system, etc.).

Let's look at a more in-depth example with multiple contexts at work using a company that provides a self publishing app for users to upload, create, edit and publish ebooks. In this example, we'll assume we have the following models: `User`, `Role`, `Permission`, `Publisher`, `Series` and `Book`. The user, role and permission models are self explanatory, and the others should be fairly obvious.  A publisher is the organization under which series and books are organized, a series represent a collection of books, and a book is a book. Multiple users may be linked to a publisher, each with varying abilities based on their roles and permissions.

In this scenario, you might have a set of roles defined with a global context, like the following:

    admin = Role.create(:slug => 'admin', :level => 100)
    manager = Role.create(:slug => 'manager', :level => 70)
    employee = Role.create(:slug => 'employee', :level => 60)

You would then assign those roles, also within a global context, to the user accounts for employees of the company and either allow or deny them various abilities around the site based on those roles. Engineers and officers could have the 'admin' role and be able to change settings that control the applications behavior, 'managers' might be allowed to pull reports for various departments, and an 'employee' might be given some other abilities beyond those of normal users.

You can assign roles within a global context like this:

    user = User.find(1)
    user.assign_role(:admin)

And you can check for roles using the `has_role?` method:

    user.has_role?(:admin)  # => true

These same roles could also be used within a context to give users special abilities. For example, you might assign the role of 'admin' within the context of the `Publisher` class to some of your employee users:

    bob = User.find(1)
    bob.assign_role(:admin, Publisher)   # this would make the user an admin for publishers, but not a global admin

Then you could allow any users possessing that global 'admin' role, **but assigned within the `Publisher` context,** the ability to edit, update, destroy, etc. for any and all individual publishers. This user **would not** possess the global admin abilities mentioned above (unless you also separately assign the admin role within a global context). You'd check if a user possesses the role by passing the context in as well:

    bob.has_role?(:admin)                 # => false (bob is a publisher admin, but not a global admin)
    bob.has_role?(:admin, Publisher)      # => true
    user.has_role?(:admin, Publisher)     # => true (because this user has the global admin role and it bubbles up the chain)

By default zuul does not force the use of the provided context, but instead bubbles up the chain when looking for roles/permissions. In this example, if a user possesses the global admin role assigned within a global context, they would also be allowed the same abilities as the `Publisher` admin.

If you were to tell zuul to force the context though, it would not look up the chain and the user would be required to possess the admin role within the specific context provided. If you wanted **only** users who possessed the admin role within the `Publisher` context and did not want to include global admins, you can force the context like this:

    # passing true for force_context
    user.has_role?(:admin, Publisher, true)   # => false (this user does not possess the role within the context)

However right now this same check would also fail for bob, even though he has the admin role assigned within the `Publisher` context.  The reason is because forcing the context requires the role or permissions to be both **defined and assigned** within the force context:

    bob.has_role?(:admin, Publisher, true)    # => false (this also fails because by default it wants the role to be DEFINED AND ASSIGNED within the forced context)

The catch here is that forcing the context for the role check will also force the context for the lookup of the role via the slug. Since our admin role is **defined** in the global context, this lookup will fail before we even check the role against the subject (even though it is **assigned** to bob within the forced `Publisher` context). In this case, as far as `has_role?` is concerned the publisher admin role doesn't even exist (because it's not bubbling up). In order for this to work using a slug, the admin role would have to be both defined and assigned within the `Publisher` context.

You can however work around this by passing a role or permission object (instead of a slug) to pretty much all the authorization methods. So for our previous example to work *using the global roles defined in our example and assigned within the `Publisher` context*, we'd actually want to do this:

    global_admin = Role.find(1)   # this would be our global admin role
    bob.has_role?(global_admin, Publisher, true)    # => true (because the role is provided so there is no lookup by slug, and it is assigned within the context being forced)
    user.has_role?(global_admin, Publisher, true)   # => false (this still doesn't match because the user is assigned in the global context and the match doesn't bubble when forced)

Otherwise you can break out your role definitions by context and create a separate publisher admin role, in which case the slug lookup and the match will work:

    publisher_admin = Role.create(:slug => 'admin', :level => 100, :context => Publisher)
    bob.assign_role(:admin, Publisher)
    bob.has_role?(:admin, Publisher, true)  # => true

A few more examples should help clarify:

    # this is our global admin role
    global_admin = Role.create(:slug => 'admin', :level => 100)
    # this is our publisher admin role
    publisher_admin = Role.create(:slug => 'admin', :level => 100, :context => Publisher)
    
    user = User.find(1)
    
    user.assign_role(:admin)                        # this will use the global context, so it will find the global_admin role and assign it within the global context
    user.has_role?(:admin)                          # => true
    user.has_role?(:admin, Publisher)               # => true (it bubbles up the context chain for the lookup and the match)
    user.has_role?(:admin, Publisher, true)         # => false (since we're forcing context, it finds the publisher_admin role and can't make a match)
    user.remove_role(:admin)
    
    user.assign_role(:admin, Publisher)             # this will find the publisher_admin role and assign it within the Publisher context
    user.has_role?(:admin)                          # => false (the user is not a global admin)
    user.has_role?(:admin, Publisher)               # => true
    user.has_role?(:admin, Publisher, true)         # => true (the role is defined and assigned within the forced context, so it matches)
    user.remove_role(:admin, Publisher)
    
    # use the global role, but assign it within the Publisher context, and force the context for the match
    user.assign_role(global_admin, Publisher)       # this assigns the global_admin role within the assigned context of Publisher
    user.has_role?(:admin)                          # => false (the global_admin role is looked up, but the user is not assigned the role in a global context)
    user.has_role?(:admin, Publisher)               # => false (even though we're not forcing context here, because a Publisher admin role exists, that one is preferred over the global admin role in the lookup)
    user.has_role?(global_admin, Publisher)         # => true (using the actual role object means the context is only used to match the role since it doesn't have to be looked up)
    user.has_role?(:admin, Publisher, true)         # => false (the Publisher admin role is preferred in the lookup and no match is made)
    user.has_role?(global_admin, Publisher, true)   # => true (since we provide the role object there is no lookup, and since the role we provided is assigned within the force context of Publisher, there is a match)

Now, to get back to our publishing example.

A user may also be assigned one of these global roles **within the context of a specific publisher**. Part of the requirements for your application might be for a new user to either create or join a publisher organization when they first sign up. When creating that publisher organization the user should be assigned as an 'admin' **just for that publisher**. Publisher admins would have the ability to invite or remove users as collaborators for their publisher, edit any of the publisher profile information or series or book content, etc. **but not edit any other publisher's info/content**.

    user = User.find(1)
    publisher = Publisher.find(1)
    user.assign_role(:admin, publisher)   # or just user.assign_role(:admin, Publisher.find(1))

And now you can update your code to allow these publisher admins to do various things within the context of the publisher organization to which they belong. As with the class level context above, unless you choose to force the context the role check will bubble up the context chain, so any `Publisher` context admin users or any global admin users will be allowed these same abilities.

As mentioned, publisher admin users would be able to invite other users to join their organization and assign them roles. In that case, you could also reuse the 'manager' and 'employee' global roles within the individual publisher context. The publisher admin could assign those roles to other users within the publisher organization, and they would be allowed different abilities within the publisher context (maybe employees can only edit books, but managers can delete and create new series).

So now we've defined a few global roles, and we're using those roles in a few different contexts, but we've decided we want to introduce an 'editor' role for publishers. The editor role should be just below admins and just above managers. We don't have any use for the editor role outside the publisher context however, so instead of defining it at the global level, we'll define it at the `Publisher` level. That way we can use it to give users the editor role within publisher contexts, but it's not unnecessarily polluting our global or other class level context space.

    editor = Role.create(:slug => 'editor', :level => 80, :context => Publisher)
    user = User.find(1)
    user.assign_role(:editor, Publisher.find(1))  # even though it COULD be used at the class level, here we're using the role to make the user an editor for just his own publisher instance

Because of the context chain, you can define as simple or complex of a set of roles and permissions as you want. If you want to keep one global set of roles and assign them within a context (or no context) you can. If you want to create a separate set of roles for each resource in your application, you can do that too. It's entirely up to you how to structure your abilities and how you'd like to mix-n-match everything.

###Scoping
With the context chain outlined above zuul is already extremely flexible. But in order to add another level of customizability (and to keep unnecessary methods from polluting the ActiveRecord namespace), authorization scopes have been implemented as well. Each of the authorizaton objects is scoped to a provided namespace (the default is `:default`), which allows the object to be used in more than one scope. You may provide a named scope when defining the model `acts_as_authorization_*` which you may then use to access authorization methods within that scope. If a `:default` scope does not yet exist, your named scope will be aliased to `:default`.

Let's use an example of a web based role playing game. Let's say you have a website with multiple components - an HTML5 role playing game you're building, user profiles and discussion forums for users to discuss bugs, strategies, etc. In our example, we'll assume you have your default `User` model and `Role` and `Permission` models that you use outside of the game component to define roles like `:forum_user` to grant access to the forums, or `:banned` to prevent users from even logging into the webiste. Your `User` model would probably be defined with something like the following:

    class User < ActiveRecord::Base
      acts_as_authorization_subject # this uses the defaults, which point to the Role and Permission classes
      
      # the rest of your model stuff would be here
    end

Now what you'd like to do, is allow those same `User` objects to be assigned a `Level` and `Skill` for the game component. You plan on assigning skills to a level, and then assigning levels to each user as they progress through the game. Then various activities in the game will be based on whether or not a user possesses certain skills or is of a certain level. You can create a new scoped authorization subject for `User` that uses those new classes:

    class User < ActiveRecord::Base
      acts_as_authorization_subject # this uses the defaults, which point to the Role and Permission classes
      acts_as_authorization_subject :scope => :character, :role_class => :level, :permission_class => :skill
      
      # the rest of your model stuff would be here
    end

    class Level < ActiveRecord::Base
      acts_as_authorization_role :permission_class => :skill  # the default subject model is User, so no need to specify it
      # you don't need to scope this to :character unless you want to, and since there is no other scope on this model, :character would still be aliased to :default
    end
    
    class Skill < ActiveRecord::Base
      acts_as_authorization_permission :role_class => :level    # the default subject model is User, so no need to specify it
      # you don't need to scope this to :character unless you want to, and since there is no other scope on this model, :character would still be aliased to :default
    end

This would add an authorization scope of `:character` to `User` objects that can be used (with the `auth_scope` method) instead of the default:

    user = User.find(1)
    user.auth_scope(:character) do
      has_role_or_higher?(:level_10)  # check if the user is level 10 or greater
      has_permission?(:dual_wield)    # check if the user has the :dual_wield skill
    end

    user.has_role?(:forum_user)  # this uses the default scope to check for the :forum_user role

You might then even want to use contextual permissions within that scope so you can do things like assign the `:dual_wield` skill within the context of a weapon (swords, maces, axes, etc.).

*There are plans to implement some dynamic aliasing, to allow for methods like `has_level?` to be aliased to `has_role?`, but for now you have to use the "role" and "permission" methods.*

##Access Control DSL
Zuul's access control DSL is essentially just a custom `before_filter` for your controllers that is configured via the `access_control` method. Within the access control block, you can use the DSL methods to allow or deny access to your controller actions based on roles and permissions. Take a look at the Getting Started section for some simple examples.

###Configuring `access_control` filters
There are a number of arguments you can supply to your access control filters to control how they behave, including how strict they are, providing a default context or scope to be used by the underlying authorization system, and more. Just like everywhere else, you can set the defaults with a global config initializer, or you can override them with arguments for individual filters.

Here is an example of passing a couple arguments to the filter:

    class ExampleController < ApplicationController
      access_control :default => :allow, :mode => :quiet do
        # rules go here
      end
    end

This sets the mode to `:quiet` which surpresses any access denied errors (for custom handling) and sets the default matching strictness to `:allow` (which is less strict than the standard default of `:deny`).

**TODO: add a table of arguments and what they do**

###Default matching behavior
Zuul allows you to define how strict your access control filters should be by defining the default matching behavior. The two options are `:allow` and `:deny`, and the default is `:deny` which is more strict. Your rules are all matched individually and then evaluated based on the behavior you specify.

The following table illustrates the differences:

<table>
<tr>
<th>Rules</th>
<th><code>:allow</code></th>
<th><code>:deny</code></th>
</tr>
<tr>
<td>No rules were matched.</td>
<td>allowed</td>
<td>denied</td>
</tr>
<tr>
<td>Some <code>allow</code> rules matched, no <code>deny</code> rules matched.</td>
<td>allowed</td>
<td>allowed</td>
</tr>
<tr>
<td>No <code>allow</code> rules matched, some <code>deny</code> rules matched.</td>
<td>denied</td>
<td>denied</td>
</tr>
<tr>
<td>Some <code>allow</code> rules matched and some <code>deny</code> rules matched.</td>
<td>allowed</td>
<td>denied</td>
</tr>
</table>


###Defining rules
To check for roles and permissions, you can use the `roles` and `permissions` methods, combined with `allow` and `deny` rules. The `roles` and `permissions` methods accept a list of roles or permissions and a block of rules. Within a `roles` or `permisisons` block, the `allow` and `deny` methods accept a list of actions for which to allow or deny access. By default all actions, roles and permissions are inherited from parent blocks.

    class ExampleController < ApplicationController
      access_control do
        roles :admin, :moderator do
          allow :index, :show, :create, :update, :destroy
        end

        permissions :edit do
          allow :update
        end

        # this is unnecessary since the default matching order is :deny, anyone who is not allowed is denied.
        # it is here as an example of the deny method.
        roles :banned do
          deny :index, :show, :create, :update, :destroy
        end
      end
    end

As mentioned above, all actions, roles and permissions are inherited when nesting blocks of rules. Because the `access_control` filter applies to all actions by default, this means that rules can sometimes be simplified if they apply to all actions.

    class AdminController < ApplicationController
      access_control do
        roles :admin { allow }  # access_control applies to all actions by default, and they are inherited if we don't pass any arguments to allow
      end
    end

This can be made even simpler with the `allow_roles`, `deny_roles`, `allow_permissions` and `deny_permissions` methods.  These methods will allow you to allow or deny roles and permissions in one shot and will apply to the currently active set of actions (from the parent block).

    class AdminController < ApplicationController
      access_control do
        allow_roles :admin  # access_control applies to all actions by default, and allow_roles inherits the actions from it's parent block
        deny_permissions :banned
      end
    end

Pretty much all the DSL methods are also aliased to singular forms, so you can use `role` instead of `roles` or `deny_permission` instead of `deny_permissions` where it makes your code more readable.

###Including or excluding controller actions
By default the access control filters are applied to all actions within your controller, which means all your rules will be evaluated for every action. Sometimes though, you may want to apply different rules to different actions, exclude some actions entirely, or only apply access control to specific actions. There are a few different ways to do this.

If you want to completely exclude certain actions from access control, or you want to only apply access control to a few actions in your controller, the `access_control` filter accepts the same `:only` and `:except` arguments as the standard `before_filter`. Let's say you wanted to deny access to everyone except admin users for all actions in your controller except 'index'.

    class StrictController < ApplicationController
      access_control :default => :deny, :except => [:index] do
        roles :admin do
          allow :create, :update, :destroy
        end
      end
    end

In the above example, if you **did not** specify the 'index' action in the `:except` argument, no one would be allowed to access it. The filter would be evaluated and because the default behavior is `:deny`, and because no one is explicitly granted access to the index action in the rules, everyone would be denied access. Passing the index action here prevents the access control block from ever being evaluated when requesting index (which lets everyone through).

Now let's take that same example, and let's say instead of allowing everyone access to the index action, we only want 'moderators' and 'admins' to have access.

    class StrictController < ApplicationController
      access_control :default => :deny do
        actions :index do
          roles :admin, :moderator do
            allow # the actions are inherited from the parent block here, so the index action is automatically included and does not need to be passed to allow
          end

          # OR for shorter syntax in this case, you could do

          allow_roles :admin, :moderator
        end

        roles :admin do
          allow :create, :update, :destroy
        end
      end
    end

Here we use the `actions` method to specify the actions we want to define rules for, then we add the rules to allow the admin and moderator roles access. You can also see an example of the shortcut `allow_roles`, which just uses any actions already defined within the block to allow the roles you provide.

###Contexts and scoping
You can specify a context and scope for your access control filters, and when provided all defined rules will be matched within that context and/or scope.

The first option is to pass the `:context` or `:scope` arguments directly to the filter:

    # using our publisher example from earlier
    class ContextualController < ApplicationController
      access_control :context => Publisher do
        roles :admin, :editor do
          # this will use the Publisher context when checking if the user posesses the admin or editor roles
          allow :create, :update, :destroy 
        end
      end
    end
    
    # using our web based RPG example from earlier
    class ScopedController < ApplicationController
      access_control :scope => :character do
        roles :level_10 do
          # this will use the :character auth scope on our user to check if they are level_10 (using the Level model defined for that scope)
          allow :enter_dungeon, :invite_to_party
        end
      end
    end

The `:context` can either be a class, an object or a reference to an instance variable or method.

    class ContextualController < ApplicationController
      access_control :context => Publisher.find(1) do
        # rules...
      end
    end
    
    class ContextualController < ApplicationController
      access_control :context => :get_publisher do
        # rules...
      end

      def get_publisher
        Publisher.find(params[:id])
      end
    end
    
    class ContextualController < ApplicationController
      before_filter :load_publisher
      access_control :context => :@publisher do
        # rules...
      end

      def load_publisher
        @publisher = Publisher.find(params[:id])
      end
    end

Another option is to use the `context` and `scope` DSL methods within the block to define a subset of rules.

    # an example of an "events" controller from a calendar application
    class EventsController < ApplicationController
      before_filter :load_event

      access_control do
        roles all_roles do  # this uses the all_roles helper to allow anyone to view events
          allow :show
        end

        roles :admin do
          allow :destroy    # this allows global site admins to destroy events
        end
        
        context :@event do  # uses the @event instance var set in the :load_event before filter
          roles :owner do
            # this will check for the 'owner' role within the context of the event
            allow :invite, :kick, :destroy
          end
          roles :participant do
            # this will check for the 'participant' role within the context of the event
            allow :leave
          end
        end
      end

      def load_event
        @event = Event.find(params[:id])
      end
    end

    # using the web based RPG example again
    class DungeonController < ApplicationController
      access_control do
        # technically this is not necessary, as the default behavior is to deny access unless there is an allow match. it's here for the sake of the example.
        deny_roles :banned, logged_out    # this denies logged out users (using the pseudo-role) and any :banned users from all actions

        scope :character do
          roles :level_10 do
            or_higher do
              allow :enter    # this uses the :character scope to check if the user is level 10 or greater
            end
          end
        end
      end
    end

You can also specify whether or not to force the context when matching rules. The default is false unless you've overridden it globally, and whatever value is set is passed through to the authorization models and methods. Like context and scope, you can specify this option as an argument or use the DSL method.

    class ExampleController < ApplicationController
      access_control :context => Publisher, :force_context => true do
        roles :admin do
          allow :edit, :update, :destroy      # the context would be forced when checking against the admin role, requiring the Publisher admin role (global admins would NOT be matched)
        end
      end
    end
    
    class ExampleController < ApplicationController
      access_control :context => Publisher do
        force_context do
          roles :admin do
            allow :edit, :update, :destroy    # the context would be forced when checking against the admin role, requiring the Publisher admin role (global admins would NOT be matched)
          end
        end
      end
    end

###Chaining filters together
Access control filters can be chained together, allowing you to split up rules into separate blocks. This is mostly useful if you've got controllers that inherit from a parent and you don't want to re-define rules over and over again. For example, you may want to deny access to banned users in your `ApplicationController`, then provide an additional set of rules for each of your controllers.

    class ApplicationController < ActionController::Base
      access_control :default => :allow do
        deny_roles :banned
      end
    end

    class SomeOtherController < ApplicationController
      access_control do
        # additional rules here
      end
    end

It's important to know that any arguments passed to a previous filter will be persisted unless overridden. So in the above example, the second `access_control` block would inherit the `:default => :allow` configuration (unless we were to pass `:default => :deny`). This includes configuration for things like contexts, scoping, etc.

There is a `:collect_results` argument for `access_control` which determines how results are passed between chained access control filters. It can be set to `true` or `false`, and the default is `false`.

When `:collect_results` is set to `false` all individual rule matches are passed through to the final filter in the chain, and are then evaluated together based on the default matching behavior set for that filter (either `:allow` or `:deny`).

When `:collect_results` is set to `true` each block of rules is evaluated inline based on the default matching behavior for that filter (either `:allow` or `:deny`), and that single collective result is passed on to the next filter to be combined and evaluated with the next set of rules. 

##Controller and View Helpers
Zuul includes a few helper methods for your controllers and views to make it easier to perform actions or display content based on whether or not a user possesses roles or permissions. Normally, you might do something like this in a controller action:

    def do_thing
      # some code here that should be executed for everyone
      if current_user && current_user.has_role?(:admin)
        # do something special only for admin users
      else
        # do something else for everyone else
      end
    end

Or like this in a view:

    <% if current_user && current_user.has_role?(:admin) %>
      <li><%= link_to "Admin Dashboard", admin_dashboard_url %></li>
    <% end %>

With zuul's helpers, you can clean that up a little bit:

    def do_thing
      # some code here that should be executed for everyone
      for_role(:admin) do
        # do something special only for admin users
      end.else do
        # do something else for everyone else
      end
    end

    <% for_role(:admin) do %>
      <li><%= link_to "Admin Dashboard", admin_dashboard_url %></li>
    <% end %>

The helpers can be nested and chained together, so you can do stuff like:

    for_role(:admin) do
      # do stuff for admins
      for_permission(:super_special) do
        # do stuff for admins w/ the super_special permission
      end
    end.else_for(:moderator) do
      # do stuff for moderators
    end.else do
      # do stuff for everyone else
    end

**TODO: add a table with a list of helper methods**

##Credit and Thanks
* [Mark Rebec](https://github.com/markrebec) is the current author and maintainer of zuul.
* Thanks to [Wes Gibbs](https://github.com/wgibbs) for creating the original version of zuul and for allowing me to take over maintenance of the gem.
* [Oleg Dashevskii's](https://github.com/be9) library [acl9](https://github.com/be9/acl9) is another great authorization and access control solution that provides similar functionality. While acl9 does not support the same context chain (it actually sort of works in the other direction) or authorization scoping that zuul does, it does allow working with roles in context of resources, and it provided much inspiration when building the ActionController DSL included in zuul. I'd advise taking a look at acl9 and comparing it with zuul to see which better fits your needs.
* The name is a reference to the film [Ghostbusters](http://en.wikipedia.org/wiki/Ghostbusters) (1984), in which an ancient Sumerian deity called [Zuul](http://www.gbfans.com/wiki/Zuul), also known as The Gatekeeper, possesses the character Dana Barrett.

##Contributing

##TODO
* continue filling out readme + documentation
* write specs for generators
* write specs for all the controller mixins
* add some built-in defaults for handling access denied errors and rendering a default template and/or flash message
* clean up errors/exceptions a bit more
* i18n for messaging, errors, templates, etc.
* add a rake task that can generate a map/report of roles and permissions + their contexts and how everything is assigned and linked together (maybe use graphviz?) (maybe even look for where the roles/perms are used in the codebase?)
* create a logger for the ACL DSL stuff and clean up the logging there
* abstract out ActiveRecord, create ORM layer to allow other datasources

##Copyright/License
