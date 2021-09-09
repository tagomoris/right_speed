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
              # TODO: keep-alive?
              Ractor.yield(conn, move: true) # to yield closing connections to ConnectionCloser
            rescue => e
              logger.error { "Unexpected error: #{e.message}\n" + e.backtrace.map{"\t#{_1}\n"}.join }
              # TODO: print backtrace in better way
            end
          end
          logger.info { "Worker#{id}: Finishing the Ractor" }
          Ractor.yield(:closing) # to tell the outgoing path will be closed when stopping
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
