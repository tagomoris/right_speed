require_relative 'base'

module RightSpeed
  module Worker
    class Accepter < Base
      def configure(sock)
        @sock = sock
      end

      def run
        @ractor = Ractor.new(@id, @sock) do |id, sock|
          while conn = sock.accept
            begin
              data = conn.read
              # TODO: process it
              logger.info "[read|#{id}] Data: #{data}"
              conn.write "200 OK"
            ensure
              conn.close rescue nil
            end
          end
        end
      end

      def wait
        @ractor.take
      end
    end
  end
end
