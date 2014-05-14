module Zuul
  module ActionController
    module DSL
      class Roles < Actionable
        def match?(role)
          (@or_higher && subject.auth_scope(@scope, @context, @force_context) { |context, force_context| has_role_or_higher?(role, context.to_context, force_context) }) || (!@or_higher && subject.auth_scope(@scope, @context, @force_context) { |context, force_context| has_role?(role, context.to_context, force_context) })
        end
        
        def allow(*actions)
          log_timer_start = Time.now.to_f
          actions = actions[0] if actions.length == 1 && actions[0].is_a?(Array)
          actions.concat(@actions)
          return if @roles.empty? || actions.empty?
          if actions.map(&:to_sym).include?(@controller.params[:action].to_sym)
            @roles.each do |role|
              if (role == logged_out && subject.nil?) ||
                 (role == logged_in && !subject.nil?)
                @results << true
                return
              end
              
              next if subject.nil? # keep going in case :_zuul_logged_out is specified
              
              if allow?(role)
                logger.debug "  \e[1;33mACL (#{((Time.now.to_f - log_timer_start) * 1000.0).round(1)}ms)\e[0m  \e[1mMATCH\e[0m for \e[32mallow\e[0m role \e[1m#{role.is_a?(subject.auth_scope(@scope).role_class) ? "#{role.slug}[#{role.context.to_s}]" : role}\e[0m"
                @results << true
                return
              end
              logger.debug "  \e[1;33mACL (#{((Time.now.to_f - log_timer_start) * 1000.0).round(1)}ms)\e[0m  \e[1mNO MATCH\e[0m for \e[32mallow\e[0m role \e[1m#{role.is_a?(subject.auth_scope(@scope).role_class) ? "#{role.slug}[#{role.context.to_s}]" : role}\e[0m"
            end
          end
        end
        
        def deny(*actions)
          log_timer_start = Time.now.to_f
          actions = actions[0] if actions.length == 1 && actions[0].is_a?(Array)
          actions.concat(@actions)
          return if @roles.empty? || actions.empty?
          if actions.map(&:to_sym).include?(@controller.params[:action].to_sym)
            @roles.each do |role|
              if (role == logged_out && subject.nil?) ||
                 (role == logged_in && !subject.nil?)
                @results << false
                return
              end
              
              next if subject.nil? # keep going in case :_zuul_logged_out is specified
              
              if deny?(role)
                logger.debug "  \e[1;33mACL (#{((Time.now.to_f - log_timer_start) * 1000.0).round(1)}ms)\e[0m  \e[1mMATCH\e[0m for \e[31mdeny\e[0m role \e[1m#{role.is_a?(subject.auth_scope(@scope).role_class) ? "#{role.slug}[#{role.context.to_s}]" : role}\e[0m"
                @results << false
                return
              end
              logger.debug "  \e[1;33mACL (#{((Time.now.to_f - log_timer_start) * 1000.0).round(1)}ms)\e[0m  \e[1mNO MATCH\e[0m for \e[31mdeny\e[0m role \e[1m#{role.is_a?(subject.auth_scope(@scope).role_class) ? "#{role.slug}[#{role.context.to_s}]" : role}\e[0m"
            end
          end
        end

        def or_higher(&block)
          opts = options.merge(:or_higher => true)
          dsl = self.class.new(@controller, opts)
          dsl.instance_eval(&block) if block_given?
          
          @results.concat dsl.results
        end

        protected

        def initialize(controller, opts={})
          super
          opts = {:or_higher => false}.merge(opts)
          @or_higher = opts[:or_higher]
        end
      end
    end
  end
end
