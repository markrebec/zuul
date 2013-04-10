module Zuul
  module Exceptions
    class UndefinedScope < StandardError
      def initialize(msg = "The requested scope does not exist")
        super
      end
    end
  end
end
