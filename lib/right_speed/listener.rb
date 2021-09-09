# frozen_string_literal: true

require_relative "logger"

module RightSpeed
  module Listener
    def self.setup(listener_type:, host:, port:, backlog: nil)
      case listener_type
      when :roundrobin
        RoundRobinListener.new(host, port, backlog)
      else
        SimpleListener.new(host, port, backlog)
      end
    end

    class SimpleListener
      attr_reader :sock

      def initialize(host, port, backlog)
        @host = host
        @port = port
        @backlog = backlog
        @sock = nil
      end

      def run(_processor)
        @running = true
        @sock = TCPServer.open(@host, @port)
        @sock.listen(@backlog) if @backlog
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

    class RoundRobinListener < SimpleListener
      def run(processor)
        @running = true
        @ractor = Ractor.new(@host, @port, @backlog, processor) do |host, port, backlog, processor|
          logger = RightSpeed.logger
          sock = TCPServer.open(host, port)
          sock.listen(backlog) if backlog
          logger.info { "listening #{host}:#{port}" }
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
