# Zuul
Contextual Authorization and Access Control for ActiveRecord and ActionController respectively, along with a few handy extras (like generators) for Rails. The name is a reference to the film [Ghostbusters](http://en.wikipedia.org/wiki/Ghostbusters) (1984), in which an ancient Sumerian deity called [Zuul](http://www.gbfans.com/wiki/Zuul), also known as The Gatekeeper, possesses the character Dana Barrett.

### Zuul is undergoing some changes!
[Wes Gibbs](https://github.com/wgibbs) has been kind enough to transfer maintenance of the gem to myself ([Mark Rebec](https://github.com/markrebec)), and in turn I'm taking some time to revamp and upate Zuul to provide some new features and make everything compatible with the latest versions of ActiveRecord and ActionController.

The version is being bumped to `0.1.2` to start, and version history is being maintained so we don't break any existing implementations. This also allows continued use, maintenance and forking of any previous versions of the gem if anyone should prefer to use a version prior to the switchover.

I can't thank Wes enough for allowing me to take over Zuul, rather than introducing yet-another-competing-access-control-gem for folks to sort through!

## Features
Zuul provides an extremely flexible authorization solution for ActiveRecord wherein roles and (optionally) permissions can be assigned within various contexts, along with an equally robust access control DSL for ActionController and helpers for your views. It can be used with virtually any authentication system (I highly recommend [devise](http://github.com/platformatec/devise) if you haven't chosen one yet), and it provides the following features:

* **Completely Customizable:** Allows configuration of everything - models used as authorization objects, how the context chain behaves, how access control rules are evaluated, and much more. 
* **Optional Permissions:** Use of permissions is optional, and when enabled can be assigned to roles or directly to individual subjects if you require that level of control.
* **Authorization Models:** Can be used with your existing models, and doesn't require any database modifications for subjects (like users) or resource contexts (like blog posts). You also have the choice of generating new role and/or permissions models, or utilizing existing models as those roles and permissions - for example, if you were building a game and you wanted your `Level` and `Achievement` models to behave as "Roles" and "Permissions" for a `Character`, which would allow/deny that character access to various `Dungeon` objects.
* **Contextual:** Allows creating and assigning abilities within a provided context - either globally, at the class level, or at the object level - and contexts can be mixed-and-matched (within the context chain). *While contexts are currently required for Zuul to work, you can "ignore" them by simply creating/managing everything at the global level, and there are plans to look into making contexts optional in future versions.*
* **Context Chain:** There is a built-in "context chain" that is enforced when working with roles and permissions. This allows for both a high level of flexibility (i.e. roles can be applied within child contexts) and finer level of control (i.e. looking up a specific role within a specific context and not traversing up the chain), and can be as simple or complex as you want.
* **Scoping:** All authorization methods are scoped, which allows the same model to act as an authorization subject for multiple scopes (each with it's own role/permission models).
* **Controller ACL:** Provides a flexible access control DSL for your controllers that gives the ability to allow or deny access to controller actions and resources based on roles or permissions, and provides a few helper methods and pseudo roles for logged in/out.
* **Helpers:** There are a few helpers included, like `for_role`, which allow you to execute blocks or display templates based on whether or not a subject possesses the specified role/permission, with optional fallback blocks if not.

## Getting Started
Zuul &gt;= 0.1.2 works with Rails &gt;= 3.1 (probably older versions too, but it hasn't ben tested yet). To use it, ensure you're using rubygems.org as a source (if you don't know what that means, you probably are) and add this to your gemfile:

    gem `zuul`

Then run bundler to install it.

In order to use the core authorization functionality, you'll need to setup subjects and roles. Permissions are enabled in the default configuration, so if you don't specify otherwise you'll have to setup the permissions model as well. Each authorization model type has it's own default, but those can be overridden in the global initializer config, or they can be specified per-model as you're setting up authorization models.

**Authorization Subjects**
An authorization subject is the object to which you grant roles and permissions, usually a user. In order to use Zuul, you'll need to setup at least one subject model. The default model is `User`.

**Authorization Roles**
Authorization roles are the roles that can be assigned to the subject mentioned above, and then used to allow or deny access to various resources. Zuul requires at least one role model. The default model is `Role`.

**Authorization Permissions**
Authorization permissions are optional, and allow finer grained control over which subjects have access to which resources. Permissions can be assigned to roles (which are in turn assigned to subjects), or they can be assigned directly to subjects themselves, and they require that the model be setup in order to be used by roles or subjects. The default model is `Permission`.

**Authorization Resources (Contexts)**
Authorization resources, or contexts, behave as both the resources that are being accessed by a subject, as well as (optionally) a context within which roles or permissions can be created and assigned. When combined with Zuul's "context chain," this allows you to define or assign roles for specific models or even specific instances of those models. No setup is required to use a model as a resource or context, but there is some optional configuration that provides the model directly with methods to authorize against roles and permissions. Resource/context models are not required, and there are no configured defaults.

### Generating Authorization Models
It's likely you already have a `User` model (or equivalent), especially if you've already got some form of authentication setup in your app. However, you probably don't yet have any role or permission models setup unless you're transitioning from another authorization solution. Either way, you can use the provided generators to create new models or to configure existing models as authorization objects. The generators work just like the normal model generators (with a few additions) and will either create the models and migrations for you if they don't exist, or modify your models and create any necessary migrations if they do.

**Generate an authorization subject model**
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

**Generate an authorization role model**
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

**Generate an authorization permission model**
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

**Generate authorization association tables**
TODO: add instructions on generating the association tables

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
