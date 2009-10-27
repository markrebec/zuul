module Zuul
  module AC
    def self.included(controller)
      controller.extend(ClassMethods)
      # controller.before_filter(:ensure_proper_protocol)
    end

    module ClassMethods
      def restrict_access_to(roles, options = {})

      end
    end
  end

  module AR
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def valid_roles(*roles)
        attr_protected :role
        write_inheritable_attribute(:roles, roles)
        include InstanceMethods
      end


    end

    module InstanceMethods
      def self.included(base)
        base.read_inheritable_attribute(:roles).each do |role|
          class_eval <<-CODE
            def #{role}?
              self.role.to_sym == :#{role}
            end
          CODE
        end
      end

      def role
        role_name = read_attribute(:role)
        role_name && role_name.to_sym
      end

      def role=(role)
        return unless self.class.read_inheritable_attribute(:roles).include?(role.to_sym)
        write_attribute(:role, role.to_s)
      end
    end
  end
end

Class.class_eval do
  include Zuul::AR::ClassMethods
end
