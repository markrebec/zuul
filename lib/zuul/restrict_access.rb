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

      # Meant to be called from your controllers. This is
      # where you define which roles have access to which actions in the
      # controller. Examples:
      # * <code>require_user :admin</code>: Restrict access to all actions for a specific role.
      # * <code>require_user :guest, :admin, :only => :index, :show</code>: Restrict access to specific actions for specific roles.
      # * <code>require_user :only => :show</code>: Require a user but don't care about the role.
      def require_user(*roles)
        options = roles.extract_options!
        self.before_filter options do |controller|
          controller.send(:require_user, roles)
        end
      end

      # Tells its controller to check that there is no user
      # before allowing someone into an action. For example:
      # * <code>require_no_user :only => :edit, :update</code>: Don't allow access to the edit action
      # if there is a user.
      def require_no_user(options = {})
        self.before_filter options do |controller|
          controller.send(:require_no_user)
        end
      end

      # Intended to be called by ApplicationController. It mixes
      # in a set of instance methods that manage conferring or denying access to actions.
      # You can customize the behavior when a user is denied access with these
      # options:
      # * +access_denied_message+: The string that will be added to the
      #   flash[:notice] if the user has been denied access to an action.
      #   Defaults to "You must be logged in to access this page".
      # * +require_no_user_message+: The string that will be added to the
      #   flash[:notice] if the requested action requires there be NO user signed
      #   in and there is one. Defaults to "You must be logged out to access this
      #   page.".
      # * +unauthorized_redirect_path+: The name of a method, as a symbol, that
      #   will be called to determine where to redirect someone when they have
      #   been denied access. The method is expected to return a string. The
      #   default is :unauthorized_path which returns "/".
      def restrict_access(options = {})
        self.access_denied_message = options[:access_denied_message] || "You must be logged in to access this page"
        self.require_no_user_message = options[:require_no_user_message] || "You must be logged out to access this page"
        self.unauthorized_redirect_path = options[:unauthorized_redirect_path] || :unauthorized_path
        include InstanceMethods
      end
    end

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
