module Zuul
  module Exceptions
    class AccessDenied < StandardError
      def initialize(msg = "Access Denied")
        super
      end
    end
  end
end
