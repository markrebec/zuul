module Zuul
  class Context < Struct.new(:class_name, :id)

    def self.parse(*args)
      if args.length >= 2
        new(*args)
      elsif args[0].is_a?(self)
        return args[0]
      elsif args[0].is_a?(Class)
        new(args[0].name)
      elsif args[0].class.ancestors.include?(::ActiveRecord::Base) && args[0].respond_to?(:id)
        new(args[0].class.name, args[0].id)
      else
        new
      end
    end
    
    def instance?
      !class_name.nil? && !id.nil?
    end
    alias_method :object?, :instance?

    def class?
      !class_name.nil? && id.nil?
    end

    def global?
      class_name.nil? && id.nil?
    end
    alias_method :nil?, :global?

    def ==(kontext)
      class_name == kontext.class_name && id == kontext.id
    end

    def <=(kontext)
      kontext.global? || (class_name == kontext.class_name && (kontext.id.nil? || id == kontext.id))
    end

    def type
      return :nil if class_name.nil?
      return :class if id.nil?
      :instance
    end

    def type_s
      return 'global' if class_name.nil?
      return class_name if id.nil?
      "#{class_name}(#{id})"
    end

    def to_context
      return nil if class_name.nil?
      return class_name.constantize if id.nil?
      class_name.constantize.find(id)
    end
    alias_method :context, :to_context
    
    protected

    def initialize(class_name=nil, id=nil)
      raise Exceptions::InvalidContext, "Invalid Context Class" unless class_name.nil? || class_name.is_a?(String)
      raise Exceptions::InvalidContext, "Invalid Context ID" unless id.nil? || id.is_a?(Integer)
      raise Exceptions::InvalidContext if !id.nil? && class_name.nil?
      super
    end
  end
end
