module Allowables
  class Configuration
    PRIMARY_AUTHORIZATION_CLASSES = {
      :subject_class => :user,
      :role_class => :role,
      :permission_class => :permission
    }
    AUTHORIZATION_JOIN_CLASSES = {
      :role_subject_class => :role_user,
      :permission_role_class => :permission_role,
      :permission_subject_class => :permission_user
    }
    DEFAULT_AUTHORIZATION_CLASSES = PRIMARY_AUTHORIZATION_CLASSES.merge(AUTHORIZATION_JOIN_CLASSES)
    
    DEFAULT_CONFIGURATION_OPTIONS = {
      :acl_default => :deny, # :allow, :deny
      :acl_mode => :raise, # :raise, :quiet
      :acl_collect_results => false,
      :subject_method => :current_user,
      :force_context => false,
      :scope => :default,
      :with_permissions => true
    }

    attr_reader *DEFAULT_AUTHORIZATION_CLASSES.keys
    attr_reader *DEFAULT_CONFIGURATION_OPTIONS.keys

    DEFAULT_AUTHORIZATION_CLASSES.keys.concat(DEFAULT_CONFIGURATION_OPTIONS.keys).each do |key|
      define_method "#{key.to_s}=" do |val|
        @changed[key] = [send(key), val]
        instance_variable_set "@#{key.to_s}", val
      end
    end

    def changed
      @changed = {}
      to_hash.each { |key,val| @changed[key] = [@saved_state[key], val] if @saved_state[key] != val }
      @changed
    end

    def configure(args={}, &block)
      save_state
      configure_with_args args
      configure_with_block &block
      configure_join_classes if PRIMARY_AUTHORIZATION_CLASSES.keys.any? { |key| changed.keys.include?(key) }
      self
    end

    def configure_with_args(args)
      args.select { |k,v| DEFAULT_AUTHORIZATION_CLASSES.keys.concat(DEFAULT_CONFIGURATION_OPTIONS.keys).include?(k) }.each do |key,val|
        instance_variable_set "@#{key.to_s}", val
      end
    end

    def configure_with_block(&block)
      self.instance_eval(&block) if block_given?
    end

    def configure_join_classes
      [[:role, :subject], [:permission, :subject], [:permission, :role]].each do |join_types|
        join_key = "#{join_types.sort[0].to_s}_#{join_types.sort[1].to_s}_class".to_sym
        next if changed.has_key?(join_key) # don't override join table if it was provided

        namespaces = []
        join_class = join_types.map do |class_type|
          type_class = instance_variable_get "@#{class_type.to_s}_class"
          namespace = (type_class.is_a?(Class) ? type_class.name : type_class.to_s.camelize).split("::")
          class_name = namespace.slice!(namespace.length-1)
          namespaces << namespace.join("::") if namespace.length > 0
          class_name
        end.sort!.join("")
        
        join_class = "#{namespaces[0]}::#{join_class}" if namespaces.length > 0 && namespaces.all? { |ns| ns == namespaces[0] }
        instance_variable_set "@#{join_key.to_s}", join_class
      end
    end

    def save_state
      @saved_state = clone.to_hash
      @changed = {}
    end


    def to_hash
      h = {}
      DEFAULT_AUTHORIZATION_CLASSES.keys.concat(DEFAULT_CONFIGURATION_OPTIONS.keys).each do |key|
        h[key] = instance_variable_get "@#{key.to_s}"
      end
      h
    end
    alias_method :to_h, :to_hash

    def classes
      cstruct = ClassStruct.new(*DEFAULT_AUTHORIZATION_CLASSES.keys).new
      DEFAULT_AUTHORIZATION_CLASSES.keys.each do |key|
        cstruct.send("#{key.to_s}=", instance_variable_get("@#{key.to_s}"))
      end
      cstruct
    end
    
    def primary_classes
      cstruct = ClassStruct.new(*PRIMARY_AUTHORIZATION_CLASSES.keys).new
      PRIMARY_AUTHORIZATION_CLASSES.keys.each do |key|
        cstruct.send("#{key.to_s}=", instance_variable_get("@#{key.to_s}"))
      end
      cstruct
    end

    def join_classes
      cstruct = ClassStruct.new(*AUTHORIZATION_JOIN_CLASSES.keys).new
      AUTHORIZATION_JOIN_CLASSES.keys.each do |key|
        cstruct.send("#{key.to_s}=", instance_variable_get("@#{key.to_s}"))
      end
      cstruct
    end

    protected

    def initialize
      [DEFAULT_AUTHORIZATION_CLASSES, DEFAULT_CONFIGURATION_OPTIONS].each do |opts|
        opts.each do |key,val|
          instance_variable_set "@#{key.to_s}", val
        end
      end
      save_state
      super
    end

    class ClassStruct < Struct
      def keys
        each_pair.collect { |key,val| key }.to_a
      end

      def to_array
        each_pair.collect { |key,val| val }.to_a
      end
      alias_method :to_a, :to_array

      def to_hash
        Hash[each_pair.to_a]
      end
      alias_method :to_h, :to_hash
    end
  end
end
