require_relative "../logger"
require_relative "../handler"

module RightSpeed
  module Worker
    class Base
      def initialize(id:, handler:)
        @id = id
        @handler = handler
        @ractor = nil
      end

      def ractor
        @ractor
      end

      def stop
        @ractor # TODO: terminate if possible
      end
    end
  end
end
