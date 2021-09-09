require_relative "base"
require_relative "../logger"

module RightSpeed
  module Worker
    class Reader < Base
      def run
        @ractor = Ractor.new(@id, @handler) do |id, handler|
          logger = RightSpeed.logger
          while conn = Ractor.receive
            begin
              handler.session(conn).process
            rescue => e
              logger.error { "Unexpected error: #{e.message}\n" + e.backtrace.map{"\t#{_1}\n"}.join }
              # TODO: print backtrace in better way
            ensure
              # TODO: keep-alive?
              Ractor.yield(conn, move: true) # to yield closing connections to ConnectionCloser
            end
          end
          Ractor.yield(:closing, move: true) # to tell the outgoing collection will be closed when stopping
        end
      end

      def process(conn)
        @ractor.send(conn, move: true)
      end

      def wait
        @ractor.take
      end
    end
  end
end
