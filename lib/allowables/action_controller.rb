require 'allowables/action_controller/dsl'

module Allowables
  module ActionController
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def allowed?
        return true if @authorization_dsl.nil?
        @authorization_dsl.allowed?
      end
    end
    
    module ClassMethods
      def self.extended(base)
        base.send :attr_accessor, :authorization_dsl
      end

      def access_control(*args, &block)
        opts = {:default => :deny, :force_context => false, :context => nil, :actions => [], :roles => [], :permissions => []}
        opts = opts.merge(args[0]) if args.length > 0
        #[:allow, :deny].each { |auth_type| opts.merge!({auth_type => {:actions => [], :roles => [], :permissions => []}.merge(opts[auth_type])}) }
        filter_args = {}.merge(opts.select { |k,v| [:except, :only].include?(k) })
        opts.delete(:only)
        opts.delete(:except)
        
        before_filter(filter_args) do |controller|
          puts "----------------------------"
          puts "START EXECUTING ACCESS CONTROL BLOCK"
          
          controller.authorization_dsl = DSL::Base.new(controller, opts)


          if block_given?
            controller.authorization_dsl.instance_eval(&block)
          else
            controller.authorization_dsl.instance_eval do
              [:allow, :deny].each do |auth_type|
                next unless opts.has_key?(auth_type)
                auth_actions = opts[:actions]
                if !opts[auth_type].has_key?(:actions) || opts[auth_type][:actions].empty?
                  auth_actions << controller.params[:action].to_sym if auth_actions.empty?
                else
                  auth_actions.concat(opts[auth_type][:actions])
                end
                actions auth_actions do
                  if opts[auth_type].has_key?(:roles)
                    roles opts[auth_type][:roles] do
                      eval(auth_type.to_s)
                    end
                  end
                  if opts[auth_type].has_key?(:permissions)
                    permissions opts[auth_type][:permissions] do
                      eval(auth_type.to_s)
                    end
                  end
                end
              end
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
