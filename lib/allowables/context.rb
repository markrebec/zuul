module Allowables
  class Context < Struct.new(:type, :id)
    
    def to_context
      return nil if type.nil?
      return type.constantize if id.nil?
      type.constantize.find(id)
    end
    alias_method :context, :to_context
  
  end
end
