module Zuul
  module ActionController
    module DSL
      class Permissions < Actionable
        def match?(permission)
          subject.auth_scope(@scope, @context, @force_context) { |context, force_context| has_permission?(permission, context.to_context, force_context) }
        end
        
        def allow(*actions)
          log_timer_start = Time.now.to_f
          actions = actions[0] if actions.length == 1 && actions[0].is_a?(Array)
          actions.concat(@actions)
          return if subject.nil? || @permissions.empty? || actions.empty?
          if actions.map(&:to_sym).include?(@controller.params[:action].to_sym)
            @permissions.each do |permission|
              if allow?(permission)
                logger.debug "  \e[1;33mACL (#{((Time.now.to_f - log_timer_start) * 1000.0).round(1)}ms)\e[0m  \e[1mMATCH\e[0m for \e[32mallow\e[0m permission \e[1m#{permission.is_a?(subject.auth_scope(@scope).role_class) ? "#{permission.slug}[#{permission.context.to_s}]" : permission}\e[0m"
                @results << true
                return
              end
              logger.debug "  \e[1;33mACL (#{((Time.now.to_f - log_timer_start) * 1000.0).round(1)}ms)\e[0m  \e[1mNO MATCH\e[0m for \e[32mallow\e[0m permission \e[1m#{permission.is_a?(subject.auth_scope(@scope).role_class) ? "#{permission.slug}[#{permission.context.to_s}]" : permission}\e[0m"
            end
          end
        end
        
        def deny(*actions)
          log_timer_start = Time.now.to_f
          actions = actions[0] if actions.length == 1 && actions[0].is_a?(Array)
          actions.concat(@actions)
          return if subject.nil? || @permissions.empty? || actions.empty?
          if actions.map(&:to_sym).include?(@controller.params[:action].to_sym)
            @permissions.each do |permission|
              if deny?(permission)
                logger.debug "  \e[1;33mACL (#{((Time.now.to_f - log_timer_start) * 1000.0).round(1)}ms)\e[0m  \e[1mMATCH\e[0m for \e[31mdeny\e[0m permission \e[1m#{permission.is_a?(subject.auth_scope(@scope).role_class) ? "#{permission.slug}[#{permission.context.to_s}]" : permission}\e[0m"
                @results << false
                return
              end
              logger.debug "  \e[1;33mACL (#{((Time.now.to_f - log_timer_start) * 1000.0).round(1)}ms)\e[0m  \e[1mNO MATCH\e[0m for \e[31mdeny\e[0m permission \e[1m#{permission.is_a?(subject.auth_scope(@scope).role_class) ? "#{permission.slug}[#{permission.context.to_s}]" : permission}\e[0m"
            end
          end
        end
      end
    end
  end
end
