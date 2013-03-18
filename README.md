# Zuul
Contextual Authorization and Access Control for ActiveRecord and ActionController respectively, along with a few handy extras (like generators) for Rails. The name is a reference to the film [Ghostbusters](http://en.wikipedia.org/wiki/Ghostbusters) (1984), in which an ancient Sumerian deity called [Zuul](http://www.gbfans.com/wiki/Zuul), also known as The Gatekeeper, possesses the character Dana Barrett.

### Zuul is undergoing some changes!
[Wes Gibbs](https://github.com/wgibbs) has been kind enough to transfer maintenance of the gem to myself ([Mark Rebec](https://github.com/markrebec)), and in turn I'm taking some time to revamp and upate Zuul to provide some new features and make everything compatible with the latest versions of ActiveRecord and ActionController.

The Version is being bumped to `0.1.2` to start, and version history is being maintained so we don't break any existing implementations. This also allows continued use, maintenance and forking of any previous versions of the gem if anyone should prefer to use a version prior to the switchover.

I can't thank Wes enough for allowing me to take over Zuul, rather than introducing yet-another-competing-access-control-gem for folks to sort through!

## Features
Zuul provides an extremely flexible authorization solution for ActiveRecord that can be based on roles and/or optional permissions, along with an equally robust access control DSL and helpers for ActionController and your views.  It can be used with virtually any authentication system ([devise](http://github.com/platformatec/devise) is recommended if you haven't chosen one yet), and it provides the following features:

* **Completely customizable:** Allows configuration of everything - models used as authorization objects, how the context chain behaves, how access control rules are evaluated, and much more. 
* **Contextual:** Allows creating and assigning abilities within a provided context - either global, at the class level, or at the object level.
* **Context Chain:** There is a built-in "context chain" used when working with roles and permissions, allowing for both a high level of flexibility (i.e. abilities can be applied within child contexts) and finer control (i.e. looking up a specific ability within a specific context and not traversing up the chain).
* **Optional Permissions:** Use of permissions is optional, and when enabled can be assigned to roles or directly to individual subjects if you require that level of control.
* *TODO: Finish filling out high level features list*

## Installation
### Configuration
### Authorization Models
#### Generating authorization models
#### Using existing models for authorization

## The context chain

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
