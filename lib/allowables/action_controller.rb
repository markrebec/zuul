require 'allowables/action_controller/dsl'

module Allowables
  module ActionController
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def authorized?
        return true if @authorization_dsl.nil?
        @authorization_dsl.authorized?
      end
    end
    
    module ClassMethods
      def self.extended(base)
        base.send :attr_accessor, :authorization_dsl
      end

      def access_control(*args, &block)
        opts = {:default => :deny, :force_context => false, :context => nil, :actions => [], :roles => [], :permissions => []}
        opts = opts.merge(args[0]) if args.length > 0
        filter_args = {}.merge(opts.select { |k,v| [:except, :only].include?(k) })
        opts.delete(:only)
        opts.delete(:except)
        
        before_filter(filter_args) do |controller|
          logger = controller.logger
          logger.debug "----------------------------"
          logger.debug "ACCESS CONTROL BLOCK START"
          
          
          auth_dsl = controller.authorization_dsl = DSL::Base.new(controller, opts)
          
          if block_given?
            auth_dsl.instance_eval(&block)
          else
            auth_dsl.instance_eval do
              [:allow, :deny].each do |auth_type|
                next unless opts.has_key?(auth_type)
                auth_actions = opts[:actions]
                if !opts[auth_type].has_key?(:actions) || opts[auth_type][:actions].empty?
                  auth_actions << controller.params[:action].to_sym if auth_actions.empty?
                else
                  auth_actions.concat(opts[auth_type][:actions])
                end
                actions auth_actions do
                  [:roles, :permissions].each do |allowable_type|
                    if opts[auth_type].has_key?(allowable_type)
                      send "#{auth_type.to_s}_#{allowable_type.to_s}", opts[auth_type][allowable_type]
                    end
                  end
                end
              end
            end
          end
          
          
          logger.debug "ACCESS CONTROL BLOCK END"
          logger.debug "----------------------------"
          logger.debug "----------------------------"
          logger.debug "ACCESS CONTROL RESULTS"
          logger.debug auth_dsl.results.to_yaml
          logger.debug auth_dsl.authorized? ? "ALLOWED" : "NOT ALLOWED"
          logger.debug "----------------------------"

          raise Exceptions::AccessDenied unless auth_dsl.authorized?
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
