module Allowables
  module ActionController
    module Evaluators
      class ForTarget
        def for_target(&block)
          return self if @dsl.nil?
          if match?
            @controller.instance_eval do
              yield
            end if block_given?
          end
          self
        end

        def else(&block)
          return self if @dsl.nil?
          if !match?
            @controller.instance_eval do
              yield
            end if block_given?
          end
          self
        end

        def else_for(target, context=nil, force_context=nil, &block)
          return self.class.new(@controller, target, context, force_context, &block)
        end

        protected

        def initialize(controller, target, context=nil, force_context=nil, &block)
          @controller = controller
          @dsl = @controller.acl_dsl
          @target = target
          @context = context
          @force_context = force_context
          for_target &block
        end
      end

      class ForRole < ForTarget
        def match?
          (@dsl.subject.nil? && @target == @dsl.logged_out) || (!@dsl.subject.nil? && (@target == @dsl.logged_in || @dsl.subject.has_role?(@target, @context, @force_context)))
        end
      end

      class ForRoleOrHigher < ForTarget
        def match?
          (@dsl.subject.nil? && @target == @dsl.logged_out) || (!@dsl.subject.nil? && (@target == @dsl.logged_in || @dsl.subject.has_role_or_higher?(@target, @context, @force_context)))
        end
      end
      
      class ForPermission < ForTarget
        def match?
          !@dsl.subject.nil? && @dsl.subject.has_permission?(@target, @context, @force_context)
        end
      end
    end
  end
end
