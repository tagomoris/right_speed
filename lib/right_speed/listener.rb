# frozen_string_literal: true

require_relative "logger"

module RightSpeed
  DEFAULT_LISTEN_ADDRESS = "0.0.0.0"

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
        @sock = TCPServer.open(DEFAULT_LISTEN_ADDRESS, listen_port)
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
          logger = RightSpeed.logger
          sock = TCPServer.open(DEFAULT_LISTEN_ADDRESS, port)
          sock.listen(backlog)
          logger.info { "listening the port #{port}" }
          while conn = sock.accept
            logger.debug {
              _, peer_port, _, peer_addr = conn.peeraddr # proto, port, hostname, ipaddr
              "accepted a connection on the port #{port}, client: #{peer_addr}:#{peer_port}"
            }
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
