require 'allowables/action_controller/dsl'

module Allowables
  module ActionController
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def self.extended(base)
        base.send :attr_accessor, :authorization_dsl
      end

      def access_control(*args, &block)
        opts = {:default => :deny, :actions => [], :roles => [], :permissions => [], :force_context => false, :context => nil}
        opts = opts.merge(args[0]) if args.length > 0
        filter_args = {}.merge(opts.select { |k,v| [:except, :only].include?(k) })
        opts.delete(:only)
        opts.delete(:except)
        
        before_filter(filter_args) do |controller|
          puts "----------------------------"
          puts "START EXECUTING ACCESS CONTROL BLOCK"
          
          controller.authorization_dsl = DSL::Base.new(controller, opts)
          puts controller.authorization_dsl.options[:context].context.to_yaml


          if block_given?
            controller.authorization_dsl.instance_eval(&block)
          else
            controller.authorization_dsl.instance_eval do
              puts "EXECUTE WITHOUT BLOCK"
            end
          end
          
          
          puts "DONE EXECUTING ACCESS CONTROL BLOCK"
          puts "----------------------------"
          
          
          puts "ACCESS CONTROL RESULTS"
          puts controller.authorization_dsl.results.to_yaml
          puts controller.authorization_dsl.allowed? ? "ALLOWED" : "NOT ALLOWED"
          puts "----------------------------"
        end
      end

      def allow_roles(roles, *args, &block)
      end
      alias_method :allow_role, :allow_roles

      def allow_permissions(permissions, *args, &block)
      end
      alias_method :allow_permission, :allow_permissions

      def deny_roles(roles, *args, &block)
      end
      alias_method :deny_role, :deny_roles

      def deny_permissions(permissions, *args, &block)
      end
      alias_method :deny_permission, :deny_permissions
    end

  end
end

ActionController::Base.send :include, Allowables::ActionController
