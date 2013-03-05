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
        base.send :cattr_accessor, :acl_filters
        base.send :class_variable_set, :@@acl_filters, []
        base.send :attr_accessor, :authorization_dsl
      end

      def access_control(*args, &block)
        # :mode => :raise, :quiet
        opts = {:default => Allowables.configuration.acl_default, :force_context => Allowables.configuration.force_context, :context => nil, :mode => :raise, :actions => [], :roles => [], :permissions => []}
        opts = opts.merge(args[0]) if args.length > 0
        filter_args = {}.merge(opts.select { |k,v| [:except, :only].include?(k) })
        opts.delete(:only)
        opts.delete(:except)
        
        acl_filters << append_before_filter(filter_args) do |controller|
          logger = controller.logger
          logger.debug "----------------------------"
          logger.debug "ACCESS CONTROL BLOCK START"
          
          this_block = self.class.acl_filters.slice!(0)
          
          auth_dsl = controller.authorization_dsl ||= DSL::Base.new(controller)
          auth_dsl.set_options(opts)
          
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
          logger.debug "ACCESS CONTROL RESULTS"
          logger.debug "#{(auth_dsl.authorized? ? "ALLOWED" : "DENIED")} using #{auth_dsl.default.to_s.upcase}(#{auth_dsl.results.join(",")})"
          logger.debug "----------------------------"

          if self.class.acl_filters.length > 0
            logger.debug "COLLECTING ACCESS CONTROL RESULTS FOR CHAIN"
            auth_dsl.collect_results
          elsif opts[:mode] == :raise
            raise Exceptions::AccessDenied unless auth_dsl.authorized?
          end
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
