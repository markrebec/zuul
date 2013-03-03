module Allowables
  module ActionController
    module DSL
      class Base
        attr_reader :results
        attr_accessor :default, :actions, :roles, :permissions

        def actions(*actions, &block)
          actions = actions[0] if actions.length == 1 && actions[0].is_a?(Array)
          opts = options
          opts[:actions].concat(actions)
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

        def logged_out
          :_allowables_logged_out
        end
        alias_method :anonymous, :logged_out

        def logged_in
          :_allowables_logged_in
        end

        def all_actions
          @controller.class.action_methods.select { |act| !act.match(/^_callback_before_[\d]*$/) }.map(&:to_sym)
        end

        def all_roles(context=false)
          subject = @controller.send(:current_user)
          return [] if subject.nil?
          context = (context == false) ? @context : parse_context(context)
          roles = subject.role_class.where(:context_type => context.type, :context_id => context.id).to_a
          roles.concat(subject.role_class.where(:context_type => context.type, :context_id => nil).to_a) unless context.id.nil?
          roles.concat(subject.role_class.where(:context_type => nil, :context_id => nil).to_a) unless context.type.nil?
          roles
        end

        def all_permissions(context=false)
          subject = @controller.send(:current_user)
          return [] if subject.nil?
          context = (context == false) ? @context : parse_context(context)
          permissions = subject.permission_class.where(:context_type => context.type, :context_id => context.id).to_a
          permissions.concat(subject.permission_class.where(:context_type => context.type, :context_id => nil).to_a) unless context.id.nil?
          permissions.concat(subject.permission_class.where(:context_type => nil, :context_id => nil).to_a) unless context.type.nil?
          permissions
        end

        def contextual_role(slug, context=false)
          subject = @controller.send(:current_user)
          return nil if subject.nil?
          context = (context == false) ? @context : parse_context(context)
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
          @default = opts[:default]
          @actions = opts[:actions]
          @roles = opts[:roles]
          @permissions = opts[:permissions]
          @force_context = opts[:force_context]
          @context = parse_context(opts[:context])
        end

        def parse_context(context=nil)
          parsed = Struct.new(:type, :id).new
          if context.is_a?(Struct)
            parsed = context
          elsif context.is_a?(Class)
            parsed.type = context.name
          elsif !context.nil?
            if context.is_a?(String) || context.is_a?(Symbol)
              if context.to_s.match(/^@.*$/)
                context = @controller.send(:instance_variable_get, context)
              elsif @controller.respond_to?(context.to_sym)
                context = @controller.send(context)
              end
            end
            
            if context.class.ancestors.include?(::ActiveRecord::Base) && context.respond_to?(:id)
              parsed.type = context.class.name
              parsed.id = context.id
            else
              raise "Invalid Authorization Context: #{context.to_s}"
            end
          end

          parsed.instance_eval do
            def context
              return nil if type.nil?
              return type.constantize if id.nil?
              type.constantize.find(id)
            end
          end
          parsed
        end

        def allowed?
          if @default == :deny
            !(@results.empty? || @results.any? { |result| result == false })
          else
            (@results.empty? || !@results.all? { |result| result == false })
          end
        end

        protected

        def initialize(controller, opts={})
          opts = {:default => :deny, :actions => [], :roles => [], :permissions => [], :force_context => false, :context => nil}.merge(opts)
          @controller = controller
          set_options opts
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
          all_actions
        end
      end

      class Roles < Actionable
        # DSL for the roles do; blocks
        
        def allow(*actions)
          actions = actions[0] if actions.length == 1 && actions[0].is_a?(Array)
          subject = @controller.send(:current_user)
          if actions.map(&:to_sym).include?(@controller.params[:action].to_sym)
            @roles.each do |role|
              if (role == :_allowables_logged_out && subject.nil?) ||
                 (role == :_allowables_logged_in && !subject.nil?)
                @results << true
                return
              end
              
              next if subject.nil? # keep going in case :_allowables_logged_out is specified
              if @force_context && !role.is_a?(subject.role_class)
                check_role = contextual_role(role, @context)
              else
                check_role = role
              end
              puts "checking role (allow):"
              puts check_role.is_a?(subject.role_class) ? "#{check_role.slug} (#{check_role.context_type},#{check_role.context_id})" : check_role
              if subject.has_role?(check_role, @context.context)
                puts "matched"
                @results << true
                return
              end
            end
            #@results << false
          end
        end
        
        def deny(*actions)
          actions = actions[0] if actions.length == 1 && actions[0].is_a?(Array)
          subject = @controller.send(:current_user)
          if actions.map(&:to_sym).include?(@controller.params[:action].to_sym)
            @roles.each do |role|
              if (role == :_allowables_logged_out && subject.nil?) ||
                 (role == :_allowables_logged_in && !subject.nil?)
                @results << false
                return
              end
              
              next if subject.nil? # keep going in case :_allowables_logged_out is specified
              if @force_context && !role.is_a?(subject.role_class)
                check_role = contextual_role(role, @context)
              else
                check_role = role
              end
              puts "checking role (deny):"
              puts check_role.to_yaml
              if subject.has_role?(check_role, @context.context)
                puts "matched"
                @results << false
                return
              end
            end
            #@results << true
          end
        end

        #def or_higher(&block)
          # pass block to new Roles object with :or_higher flag
        #end

        protected

        # TODO allow setting :or_higher flag
        def initialize(controller, opts={})
          super
        end
      end

      class Permissions < Actionable
        # DSL for the permissions do; blocks
        
        def allow(*actions)
          actions = actions[0] if actions.length == 1 && actions[0].is_a?(Array)
          subject = @controller.send(:current_user)
          if actions.map(&:to_sym).include?(@controller.params[:action].to_sym)
            unless subject.nil?
              @permissions.each do |permission|
                puts "checking permission: #{permission} (allow)"
                if subject.has_permission?(permission, @context.context)
                  puts "matched"
                  @results << true
                  return
                end
              end
            end
            #@results << false
          end
        end
        
        def deny(*actions)
          actions = actions[0] if actions.length == 1 && actions[0].is_a?(Array)
          subject = @controller.send(:current_user)
          if actions.map(&:to_sym).include?(@controller.params[:action].to_sym)
            unless subject.nil?
              @permissions.each do |permission|
                puts "checking permission: #{permission} (deny)"
                if subject.has_permission?(permission, @context.context)
                  puts "matched"
                  @results << false
                  return
                end
              end
            end
            #@results << true
          end
        end
        
        protected

      end
    end
  end
end
