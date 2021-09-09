require_relative "base"
require_relative "../logger"

module RightSpeed
  module Worker
    class Fair < Base
      def run(listener_ractor)
        @ractor = Ractor.new(@id, @handler, listener_ractor) do |id, handler, listener|
          logger = RightSpeed.logger
          while conn = listener.take
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
        raise "BUG: Worker::Fair#process should never be called"
      end

      def wait
        # nothing to wait - @ractor.take consumes closed connections unexpectedly
        # @ractor.wait ?
      end
    end
  end
end
