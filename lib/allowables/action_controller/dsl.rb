module Allowables
  module ActionController
    module DSL
      class Base
        attr_reader :results

        def actions(*actions, &block)
          dsl = self.class.new(@controller)
          # TODO check if actions.include? current_action
          dsl.instance_eval(&block) if block_given?

          @results.concat dsl.results
          
          # actions :edit, :update do
          #   allow_roles :some_role
          #   deny_permissions :other_permission
          # end
        end
        alias_method :action, :actions

        def roles(*allowed, &block)
          dsl = Roles.new(@controller, *allowed)
          dsl.instance_eval(&block) if block_given?
          
          @results.concat dsl.results

          # roles :some_role, :other_role do
          #   allow :edit, :update
          #   deny all (all == keyword/method for all actions)
          # end
        end

        def permissions(*allowed, &block)
          dsl = Permissions.new(@controller, *allowed)
          dsl.instance_eval(&block) if block_given?
          
          @results.concat dsl.results

          # permissions :some_perm, :other_perm do
          #   allow :edit, :update
          #   deny all (all == keyword/method for all actions)
          # end
        end

        def allow_roles(*allowed)
          # roles *allowed, :allow => true
        end
        alias_method :allow_role, :allow_roles
        alias_method :allow, :allow_roles

        def allow_permissions(*allowed)
          # permissions *allowed, :allow => true
        end
        alias_method :allow_permission, :allow_permissions

        def deny_roles(*denied)
          # roles *denied, :deny => true
        end
        alias_method :deny_role, :deny_roles
        alias_method :deny, :deny_roles

        def deny_permissions(*denied)
          # permissions *denied, :deny => true
        end
        alias_method :deny_permission, :deny_permissions

        def anonymous
          # keyword for logged out user
        end

        def all_actions
          @controller.action_methodss
        end

        def all_roles
        end

        def all_permissions
        end

        protected

        def initialize(controller)
          @controller = controller
          @results = []
        end
      end

      class Actions < Base
        # DSL for the actions do; blocks
        #
        # alias allow_roles_with_actions, set actions option, call original
      end

      class Actionable < Base
        # DSL for roles/permissions
        #
        # def allow, deny for actions

        def all
          # keyword for all actions
        end
      end

      class Roles < Actionable
        # DSL for the roles do; blocks
        
        def allow(*actions)
          puts actions.to_yaml
          puts @roles.to_yaml
          # if actions are provided, check that actions.include? current action
          # check current_user against @roles
        end
        
        def deny(*actions)
          puts actions.to_yaml
          puts @roles.to_yaml
          # if actions are provided, check that actions.include? current action
          # check current_user against @roles
        end

        def or_higher(&block)
          # pass block to new Roles object with :or_higher flag
        end

        protected

        # TODO allow setting :or_higher flag
        def initialize(controller, *roles)
          raise "No Roles Provided" if roles.nil? # TODO make and use error classes
          @roles = roles
          super(controller)
        end
      end

      class Permissions < Actionable
        # DSL for the permissions do; blocks
        protected

        # TODO allow setting :or_higher flag
        def initialize(controller, *permissions)
          raise "No Permissions Provided" if permissions.nil? # TODO make and use error classes
          @permissions = permissions
          super(controller)
        end
      end
    end
  end
end
