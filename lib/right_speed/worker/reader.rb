require_relative 'base'

module RightSpeed
  module Worker
    class Reader < Base
      def run
        @ractor = Ractor.new(@id) do |id|
          logger = Base.logger
          # read and parse requests from sockets in Async manner (Fiber#scheduler ?)
          # https://github.com/fluent/fluentd/blob/master/lib/fluent/plugin/in_http.rb
          while conn = Ractor.receive
            begin
              data = conn.read
              # TODO: process it
              logger.info "[read|#{id}] Content: #{data}"
              conn.write "200 OK"
            ensure
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
