require_relative "base"
require_relative "../logger"

module RightSpeed
  module Worker
    class Reader < Base
      def run
        @ractor = Ractor.new(@id, @handler) do |id, handler|
          logger = RightSpeed.logger
          # read and parse requests from sockets in Async manner (Fiber#scheduler ?)
          # https://github.com/fluent/fluentd/blob/master/lib/fluent/plugin/in_http.rb
          while conn = Ractor.receive
            begin
              handler.session(conn).process
              # data = conn.read
              # logger.info "[read|#{id}] Content: #{data}"
              # conn.write "200 OK"
            rescue => e
              logger.error { "Unexpected error: #{e.message}\n" + e.backtrace.map{"\t#{_1}\n"}.join }
              # TODO: print backtrace in better way
              conn.close rescue nil
            end
          end
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
