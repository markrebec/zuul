module Allowables
  module Exceptions
    class InvalidContext < StandardError
      def initialize(msg = "Invalid Context")
        super
      end
    end
  end
end
