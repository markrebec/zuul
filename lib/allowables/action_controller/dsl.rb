module Allowables
  module ActionController
    module DSL
      class Base
        attr_reader :default, :context, :force_context, :actions, :roles, :permissions, :results

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

        def logged_out
          :_allowables_logged_out
        end
        alias_method :anonymous, :logged_out

        def logged_in
          :_allowables_logged_in
        end

        def anyone(context=false)
          [logged_in, logged_out]
        end

        def all_roles(context=false)
          subject = @controller.send(:current_user)
          return [] if subject.nil?
          context = (context == false) ? @context : parse_context(context)
          found_roles = subject.role_class.where(:context_type => context.type, :context_id => context.id).to_a
          found_roles.concat(subject.role_class.where(:context_type => context.type, :context_id => nil).to_a) unless context.id.nil?
          found_roles.concat(subject.role_class.where(:context_type => nil, :context_id => nil).to_a) unless context.type.nil?
          found_roles
        end

        def all_permissions(context=false)
          subject = @controller.send(:current_user)
          return [] if subject.nil?
          context = (context == false) ? @context : parse_context(context)
          found_permissions = subject.permission_class.where(:context_type => context.type, :context_id => context.id).to_a
          found_permissions.concat(subject.permission_class.where(:context_type => context.type, :context_id => nil).to_a) unless context.id.nil?
          found_permissions.concat(subject.permission_class.where(:context_type => nil, :context_id => nil).to_a) unless context.type.nil?
          found_permissions
        end

        def contextual_role(slug, context=false)
          subject = @controller.send(:current_user)
          return nil if subject.nil?
          context = (context == false) ? @context : parse_context(context)
          return subject.target_role(slug, context.to_context)
          role = subject.role_class.where(:slug => slug, :context_type => context.type, :context_id => context.id).first
          role ||= subject.role_class.where(:slug => slug, :context_type => context.type, :context_id => nil).first unless context.id.nil?
          role ||= subject.role_class.where(:slug => slug, :context_type => nil, :context_id => nil).first unless context.type.nil?
          role
        end
        alias_method :role, :contextual_role
        
        def contextual_permission(slug, context=false)
          subject = @controller.send(:current_user)
          return nil if subject.nil?
          context = (context == false) ? @context : parse_context(context)
          return subject.target_permission(slug, context.to_context)
          permission = subject.permission_class.where(:slug => slug, :context_type => context.type, :context_id => context.id).first
          permission ||= subject.permission_class.where(:slug => slug, :context_type => context.type, :context_id => nil).first unless context.id.nil?
          permission ||= subject.permission_class.where(:slug => slug, :context_type => nil, :context_id => nil).first unless context.type.nil?
          permission
        end
        alias_method :permission, :contextual_permission

        def options
          {:default => @default, :actions => @actions.clone, :roles => @roles.clone, :permissions => @permissions.clone, :force_context => @force_context, :context => @context.clone}
        end

        def set_options(opts)
          [:default, :actions, :roles, :permissions, :force_context, :mode].each do |key|
            instance_variable_set "@#{key.to_s}", opts[key] if opts.has_key?(key)
          end
          @context = parse_context(opts[:context]) if opts.has_key?(:context)
        end

        def parse_context(context=nil)
          if context.is_a?(String) || context.is_a?(Symbol)
            if context.to_s.match(/^@.*$/)
              context = @controller.send(:instance_variable_get, context)
            elsif @controller.respond_to?(context.to_sym)
              context = @controller.send(context)
            end
          end

          Allowables::Context.parse(context)
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
          opts = {:default => Allowables.configuration.acl_default, :force_context => Allowables.configuration.force_context, :context => nil, :mode => :raise, :actions => [], :roles => [], :permissions => []}.merge(opts)
          @controller = controller
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
      end

      class Roles < Actionable
        
        def allow(*actions)
          actions = actions[0] if actions.length == 1 && actions[0].is_a?(Array)
          actions.concat(@actions)
          subject = @controller.send(:current_user)
          return if @roles.empty? || actions.empty?
          if actions.map(&:to_sym).include?(@controller.params[:action].to_sym)
            @roles.each do |role|
              if (role == :_allowables_logged_out && subject.nil?) ||
                 (role == :_allowables_logged_in && !subject.nil?)
                @results << true
                return
              end
              
              next if subject.nil? # keep going in case :_allowables_logged_out is specified
              
              logger.debug "checking role (allow): #{role.is_a?(subject.role_class) ? "#{role.slug} context: #{role.context.to_s}" : role}"
              if (@or_higher && subject.has_role_or_higher?(role, @context.to_context)) || (!@or_higher && subject.has_role?(role, @context.to_context))
                logger.debug "matched"
                @results << true
                return
              end
            end
            #@results << false
          end
        end
        
        def deny(*actions)
          actions = actions[0] if actions.length == 1 && actions[0].is_a?(Array)
          actions.concat(@actions)
          subject = @controller.send(:current_user)
          return if @roles.empty? || actions.empty?
          if actions.map(&:to_sym).include?(@controller.params[:action].to_sym)
            @roles.each do |role|
              if (role == :_allowables_logged_out && subject.nil?) ||
                 (role == :_allowables_logged_in && !subject.nil?)
                @results << false
                return
              end
              
              next if subject.nil? # keep going in case :_allowables_logged_out is specified
              
              logger.debug "checking role (deny): #{role.is_a?(subject.role_class) ? "#{role.slug} context: #{role.context.to_s}" : role}"
              if (@or_higher && subject.has_role_or_higher?(role, @context.to_context)) || (!@or_higher && subject.has_role?(role, @context.to_context))
                logger.debug "matched"
                @results << false
                return
              end
            end
            #@results << true
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
        
        def allow(*actions)
          actions = actions[0] if actions.length == 1 && actions[0].is_a?(Array)
          actions.concat(@actions)
          subject = @controller.send(:current_user)
          return if subject.nil? || @permissions.empty? || actions.empty?
          if actions.map(&:to_sym).include?(@controller.params[:action].to_sym)
            @permissions.each do |permission|
              logger.debug "checking permission (allow): #{permission.is_a?(subject.permission_class) ? "#{permission.slug} context: #{permission.context.to_s}" : permission}"
              if subject.has_permission?(permission, @context.to_context)
                logger.debug "matched"
                @results << true
                return
              end
            end
          end
        end
        
        def deny(*actions)
          actions = actions[0] if actions.length == 1 && actions[0].is_a?(Array)
          actions.concat(@actions)
          subject = @controller.send(:current_user)
          return if subject.nil? || @permissions.empty? || actions.empty?
          if actions.map(&:to_sym).include?(@controller.params[:action].to_sym)
            @permissions.each do |permission|
              logger.debug "checking permission (deny): #{permission.is_a?(subject.permission_class) ? "#{permission.slug} context: #{permission.context.to_s}" : permission}"
              if subject.has_permission?(permission, @context.to_context)
                logger.debug "matched"
                @results << false
                return
              end
            end
          end
        end
        
        protected

      end
    end
  end
end
