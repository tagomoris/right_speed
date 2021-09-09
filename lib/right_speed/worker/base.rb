require_relative "../logger"
require_relative "../handler"

module RightSpeed
  module Worker
    class Base
      attr_reader :ractor

      def initialize(id:, handler:)
        @id = id
        @handler = handler
        @ractor = nil
      end

      def stop
        @ractor # TODO: terminate if possible
      end
    end
  end
end
