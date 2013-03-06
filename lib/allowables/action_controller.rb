require 'allowables/action_controller/dsl'

module Allowables
  module ActionController
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def authorized?
        return true if @acl_dsl.nil?
        @acl_dsl.authorized?
      end
    end
    
    module ClassMethods
      def self.extended(base)
        base.send :cattr_accessor, :acl_filters
        base.send :class_variable_set, :@@acl_filters, []
        base.send :attr_accessor, :acl_dsl
      end

      def access_control(*args, &block)
        opts, filter_args = parse_acl_args(*args)
        
        acl_filters << append_before_filter(filter_args) do |controller|
          logger = controller.logger
          logger.debug "  \e[1;34mACL\e[0m  Starting Access Control Block"
          
          this_block = self.class.acl_filters.slice!(0)
          
          controller.acl_dsl ||= DSL::Base.new(controller)
          controller.acl_dsl.configure opts
          controller.acl_dsl.execute &block
          
          logger.debug "  \e[1;34mACL\e[0m  Access Control Results: #{(controller.acl_dsl.authorized? ? "\e[1;32mALLOWED\e[0m" : "\3[1;31mDENIED\e[0m")} using \e[1m#{controller.acl_dsl.default.to_s.upcase}\e[0m(#{controller.acl_dsl.results.join(",")})"

          if self.class.acl_filters.length > 0
            logger.debug "  \e[1;34mACL\e[0m  Collecting ACL Results to carry through the chain..."
            controller.acl_dsl.collect_results
          elsif controller.acl_dsl.mode == :raise
            raise Exceptions::AccessDenied unless controller.acl_dsl.authorized?
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

      def parse_acl_args(*args)
        args = args[0] if args.is_a?(Array)
        filter_args = args.select { |k,v| [:except, :only].include?(k) }
        [:except, :only].each { |k| args.delete(k) }
        return [args, filter_args]
      end
    end
  end
end

ActionController::Base.send :include, Allowables::ActionController
