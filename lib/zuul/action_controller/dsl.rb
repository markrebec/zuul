module Zuul
  module ActionController
    module DSL
      class Base
        attr_reader :default, :context, :force_context, :mode, :default_block_allow_rules, :default_block_deny_rules, :actions, :roles, :permissions, :results, :subject_method, :scope

        def actions(*actions, &block)
          actions = actions[0] if actions.length == 1 && actions[0].is_a?(Array)
          opts = options
          opts[:actions].concat(actions)
          return unless opts[:actions].map(&:to_sym).include?(@controller.params[:action].to_sym)
          dsl = Actions.new(@controller, opts)
          dsl.instance_eval(&block) if block_given?
          
          @results.concat dsl.results
        end

        def context(ctxt, &block)
          opts = options.merge(:context => ctxt)
          dsl = self.class.new(@controller, opts)
          dsl.instance_eval(&block) if block_given?
          
          @results.concat dsl.results
        end

        def force_context(flag=true, &block)
          opts = options.merge(:force_context => flag)
          dsl = self.class.new(@controller, opts)
          dsl.instance_eval(&block) if block_given?
          
          @results.concat dsl.results
        end

        def roles(*allowed, &block)
          allowed = allowed[0] if allowed.length == 1 && allowed[0].is_a?(Array)
          opts = options
          opts[:roles].concat(allowed)
          dsl = Roles.new(@controller, opts)
          dsl.instance_eval(&block) if block_given?
          
          @results.concat dsl.results
        end

        def permissions(*allowed, &block)
          allowed = allowed[0] if allowed.length == 1 && allowed[0].is_a?(Array)
          opts = options
          opts[:permissions].concat(allowed)
          dsl = Permissions.new(@controller, opts)
          dsl.instance_eval(&block) if block_given?
          
          @results.concat dsl.results
        end

        def scope(scope, &block)
          opts = options.merge(:scope => scope)
          dsl = self.class.new(@controller, opts)
          dsl.instance_eval(&block) if block_given?
          
          @results.concat dsl.results
        end

        def allow_roles(*allowed)
          allowed = allowed[0] if allowed.length == 1 && allowed[0].is_a?(Array)
          roles *allowed do
            allow *@actions
          end
        end
        alias_method :allow_role, :allow_roles
        alias_method :allow, :allow_roles

        def allow_permissions(*allowed)
          allowed = allowed[0] if allowed.length == 1 && allowed[0].is_a?(Array)
          permissions *allowed do
            allow *@actions
          end
        end
        alias_method :allow_permission, :allow_permissions

        def deny_roles(*denied)
          denied = denied[0] if denied.length == 1 && denied[0].is_a?(Array)
          roles *denied do
            deny *@actions
          end
        end
        alias_method :deny_role, :deny_roles
        alias_method :deny, :deny_roles

        def deny_permissions(*denied)
          denied = denied[0] if denied.length == 1 && denied[0].is_a?(Array)
          permissions *denied do
            deny *@actions
          end
        end
        alias_method :deny_permission, :deny_permissions

        def all_actions
          @controller.class.action_methods.select { |act| !act.match(/^_callback_before_[\d]*$/) }.map(&:to_sym)
        end

        def subject
          @controller.send(@subject_method)
        end

        def logged_out
          :_zuul_logged_out
        end
        alias_method :anonymous, :logged_out

        def logged_in
          :_zuul_logged_in
        end

        def anyone
          [logged_in, logged_out]
        end

        def all_roles(context=false)
          return [] if subject.nil?
          context = (context == false) ? @context : parse_context(context)
          found_roles = subject.auth_scope(@scope).role_class.where(:context_type => context.type, :context_id => context.id).to_a
          found_roles.concat(subject.auth_scope(@scope).role_class.where(:context_type => context.type, :context_id => nil).to_a) unless context.id.nil?
          found_roles.concat(subject.auth_scope(@scope).role_class.where(:context_type => nil, :context_id => nil).to_a) unless context.type.nil?
          found_roles
        end

        def all_permissions(context=false)
          return [] if subject.nil?
          context = (context == false) ? @context : parse_context(context)
          found_permissions = subject.auth_scope(@scope).permission_class.where(:context_type => context.type, :context_id => context.id).to_a
          found_permissions.concat(subject.auth_scope(@scope).permission_class.where(:context_type => context.type, :context_id => nil).to_a) unless context.id.nil?
          found_permissions.concat(subject.auth_scope(@scope).permission_class.where(:context_type => nil, :context_id => nil).to_a) unless context.type.nil?
          found_permissions
        end

        def contextual_role(slug, context=false)
          return nil if subject.nil?
          context = (context == false) ? @context : parse_context(context)
          return subject.auth_scope(@scope) { target_role(slug, context.to_context) }
        end
        alias_method :role, :contextual_role
        
        def contextual_permission(slug, context=false)
          return nil if subject.nil?
          context = (context == false) ? @context : parse_context(context)
          return subject.auth_scope(@scope) { target_permission(slug, context.to_context) }
        end
        alias_method :permission, :contextual_permission

        def options
          {
            :default => @default,
            :actions => @actions.clone,
            :roles => @roles.clone,
            :permissions => @permissions.clone,
            :context => @context.clone,
            :force_context => @force_context,
            :subject_method => @subject_method,
            :scope => @scope,
            :mode => @mode,
            :collect_results => @collect_results,
            :allow => (@default_block_allow_rules.nil? ? @default_block_allow_rules : @default_block_allow_rules.clone),
            :deny => (@default_block_deny_rules.nil? ? @default_block_deny_rules : @default_block_deny_rules.clone),
          }
        end

        def set_options(opts)
          [:default, :actions, :roles, :permissions, :force_context, :mode, :collect_results, :subject_method, :scope].each do |key|
            instance_variable_set "@#{key.to_s}", opts[key] if opts.has_key?(key)
          end
          [:allow, :deny].each do |key|
            instance_variable_set "@default_block_#{key.to_s}_rules", opts[key] if opts.has_key?(key)
          end
          @context = parse_context(opts[:context]) if opts.has_key?(:context)
          self
        end
        alias_method :configure, :set_options

        def parse_context(context=nil)
          if context.is_a?(String) || context.is_a?(Symbol)
            if context.to_s.match(/^@.*$/)
              context = @controller.send(:instance_variable_get, context)
            elsif @controller.respond_to?(context.to_sym)
              context = @controller.send(context)
            end
          end

          Zuul::Context.parse(context)
        end

        def execute(&block)
          log_timer_start = Time.now.to_f
          if block_given?
            instance_eval(&block)
          else
            instance_eval do
              [:allow, :deny].each do |auth_type|
                auth_opts = instance_variable_get("@default_block_#{auth_type.to_s}_rules")
                next if auth_opts.nil?
                
                auth_actions = @actions
                auth_opts[:actions] = [auth_opts[:actions]] if auth_opts.has_key?(:actions) && !auth_opts[:actions].is_a?(Array)
                if !auth_opts.has_key?(:actions) || auth_opts[:actions].empty?
                  auth_actions << @controller.params[:action].to_sym if auth_actions.empty?
                else
                  auth_actions.concat(auth_opts[:actions])
                end
                
                actions auth_actions do
                  [:roles, :permissions].each do |allowable_type|
                    if auth_opts.has_key?(allowable_type)
                      send "#{auth_type.to_s}_#{allowable_type.to_s}", auth_opts[allowable_type]
                    end
                  end
                end
              end
            end
          end
          # only collect results if configured & there are more filters in the chain
          logger.debug "  \e[1;34mACL (#{((Time.now.to_f - log_timer_start) * 1000.0).round(1)}ms)\e[0m  #{(authorized? ? "\e[1;32mALLOWED\e[0m" : "\e[1;31mDENIED\e[0m")} using \e[1m#{@default.to_s.upcase}\e[0m [#{results.map { |r| "\e[#{(r ? "32mallow" : "31mdeny")}\e[0m" }.join(",")}]"
          collect_results if @collect_results && @controller.class.acl_filters.length > 0
        end

        def authorized?
          if @default == :deny
            !(@results.empty? || @results.any? { |result| result == false })
          else
            (@results.empty? || !@results.all? { |result| result == false })
          end
        end

        def collect_results
          @results = [authorized?]
        end

        protected

        def initialize(controller, opts={})
          @controller = controller
          # TODO catch 22: need config for subject_method, but need subject_method to check if subject
          opts = {:subject_method => Zuul.configuration.subject_method, :scope => :default}.merge(opts)
          config = @controller.send(opts[:subject_method]).nil? ? Zuul.configuration : @controller.send(opts[:subject_method]).auth_scope(opts[:scope]).config
          opts = {:default => config.acl_default, :force_context => config.force_context, :context => nil, :mode => config.acl_mode, :collect_results => config.acl_collect_results, :allow => nil, :deny => nil, :actions => [], :roles => [], :permissions => []}.merge(opts)
          set_options opts
          @results = []
        end

        def logger
          @controller.logger
        end
      end

      class Actions < Base
      end

      class Actionable < Base
        def all
          all_actions
        end

        def allow?(role_or_perm)
          match? role_or_perm
        end
        
        def deny?(role_or_perm)
          match? role_or_perm
        end
      end

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
