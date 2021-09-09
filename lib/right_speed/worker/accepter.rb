require_relative 'base'

module RightSpeed
  module Worker
    class Accepter < Base
      def run(sock)
        @ractor = Ractor.new(@id, sock, @handler) do |id, sock, handler|
          logger = RightSpeed.logger
          while conn = sock.accept
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

      def wait
        # nothing to wait - @ractor.take consumes closed connections unexpectedly
        # @ractor.wait ?
      end
    end
  end
end
