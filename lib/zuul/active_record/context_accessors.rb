module Zuul
  module ActiveRecord
    # These are included in roles & permissions objects and assigned roles & permissions objects
    # to provide easy access to the context for that object.
    module ContextAccessors
      def self.included(base)
        base.send :attr_accessible, :context if ::Zuul.should_whitelist?
      end

      # Return a Zuul::Context object representing the context for the role
      def context
        Zuul::Context.new context_type, context_id
      end

      # Parse a context into an Zuul::Context and set the type and id
      def context=(context)
        context = Zuul::Context.parse(context)
        self.context_type = context.klass
        self.context_id = context.id
      end
    end
  end
end
