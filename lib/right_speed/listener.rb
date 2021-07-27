module RightSpeed
  module Listener
    def self.setup(listener_type:, port:, backlog:)
      case listener_type
      when :accept
        AcceptListener.new(port, backlog)
      else
        SimpleListener.new(port, backlog)
      end
    end

    class SimpleListener
      attr_reader :sock

      def initialize(port, backlog)
        @port = port
        @backlog = backlog
        @sock = nil
      end

      def run(_processor)
        @running = true
        @sock = TCPServer.open(listen_port)
        @sock.listen(backlog)
        @sock
      end

      def wait
        # do nothing
      end

      def stop
        @running = false
        if @sock
          @sock.close rescue nil
        end
      end
    end

    class AcceptListener < SimpleListener
      def run(processor)
        @running = true
        @ractor = Ractor.new(@port, @backlog, processor) do |port, backlog, processor|
          sock = TCPServer.open(port)
          sock.listen(backlog)
          while conn = sock.accept
            processor.process(conn)
          end
        end
      end

      def wait
        @ractor.take
      end

      def stop
        @running = false
        @ractor = nil # TODO: terminate the Ractor if possible
      end
    end
  end
end
