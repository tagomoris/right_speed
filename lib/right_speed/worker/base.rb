require_relative "../logger"
require_relative "../handler"

module RightSpeed
  module Worker
    class Base
      def initialize(id:, app:)
        @id = id
        @handler = Handler.new(app)
        @ractor = nil
        # TODO: initialization of webapp
      end

      def stop
        @ractor # terminate if possible
      end
    end
  end
end
