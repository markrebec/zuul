module Zuul
  module RestrictAccess
    def self.included(controller)
      controller.extend(ClassMethods)
    end

    module ClassMethods
      def self.extended(klass)
        klass.cattr_accessor :access_denied_message
        klass.cattr_accessor :require_no_user_message
        klass.cattr_accessor :unauthorized_redirect_path
      end

      def require_user(*roles)
        options = roles.extract_options!
        self.before_filter options do |controller|
          controller.send(:require_user, roles)
        end
      end

      def require_no_user(options = {})
        self.before_filter options do |controller|
          controller.send(:require_no_user)
        end
      end

      def restrict_access(options = {})
        self.access_denied_message = options[:access_denied_message] || "You must be logged in to access this page"
        self.require_no_user_message = options[:require_no_user_message] || "You must be logged out to access this page"
        self.unauthorized_redirect_path = options[:unauthorized_redirect_path] || :unauthorized_path
        include ApplicationController::InstanceMethods
      end
    end

    module ApplicationController
      module InstanceMethods
        def require_user(*roles)
          roles.flatten!
          return true if current_user && roles.empty?
          deny_access unless roles.any? do |role|
            method = (role.to_s + "?").to_sym
            if current_user && current_user.respond_to?(method)
              current_user.send(method)
            else
              false
            end
          end
        end
        private :require_user

        def require_no_user
          if current_user
            store_location
            flash[:notice] = self.class.require_no_user_message
            redirect_to send(self.class.unauthorized_redirect_path)
            return false
          end
        end
        private :require_no_user

        def deny_access
          store_location
          flash[:notice] = self.class.access_denied_message
          redirect_to send(self.class.unauthorized_redirect_path)
          return false
        end
        private :deny_access

        def store_location
          session[:return_to] = request.request_uri
        end
        private :store_location

        def unauthorized_path
          "/"
        end
        private :unauthorized_path
      end
    end
  end
end
