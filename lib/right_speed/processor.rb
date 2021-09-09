# frozen_string_literal: true

require 'rack/builder'

require_relative 'worker/accepter'
require_relative 'worker/fair'
require_relative 'worker/roundrobin'
require_relative 'connection_closer'

module RightSpeed
  module Processor
    def self.setup(app:, worker_type:, workers:)
      app = if app.respond_to?(:call)
              app
            elsif app.is_a?(String) # rackup config path
              build_app(app)
            else
              raise "Unexpected app #{app}"
            end
      handler = Ractor.make_shareable(Handler.new(app))
      case worker_type
      when :roundrobin
        RoundRobinProcessor.new(workers, handler)
      when :fair
        FairProcessor.new(workers, handler)
      when :accept
        AcceptProcessor.new(workers, handler)
      else
        raise "Unknown worker type #{worker_type}"
      end
    end

    def self.build_app(ru)
      app = Rack::Builder.parse_file(ru)
      if app.respond_to?(:call)
        app
      elsif app.is_a?(Array) && app[0].respond_to?(:call)
        # Rack::Builder returns [app, options] but options will be deprecated
        app[0]
      else
        raise "Failed to build Rack app from #{ru}: #{app}"
      end
    end

    class Base
      def initialize(workers, handler)
        raise "BUG: use implementation class"
      end

      def configure(listener:)
        raise "BUG: not implemented"
      end

      def run
        raise "BUG: not implemented"
      end

      def process(conn)
        raise "BUG: not implemented"
      end

      def wait
        raise "BUG: not implemented"
        # ractors.each{|r| r.take}
        # finalizer.close rescue nil
      end
    end

    class RoundRobinProcessor < Base
      def initialize(workers, handler)
        @worker_num = workers
        @handler = handler
        @workers = workers.times.map{|i| Worker::RoundRobin.new(id: i, handler: @handler)}
        @closer = ConnectionCloser.new
        @counter = 0
      end

      def configure(listener:)
        @listener = listener
      end

      def run
        @workers.each{|w| w.run}
        @closer.run(@workers.map{|w| w.ractor})
        @listener.run(self)
      end

      def process(conn)
        current, @counter = @counter, @counter + 1
        @workers[current % @worker_num].process(conn)
      end

      def wait
        @workers.each{|w| w.wait}
        @closer.wait
      end
    end

    class FairProcessor < Base
      def initialize(workers, handler)
        @worker_num = workers
        @handler = handler
        @workers = workers.times.map{|i| Worker::Fair.new(id: i, handler: @handler)}
        @closer = ConnectionCloser.new
      end

      def configure(listener:)
        @listener = listener
      end

      def run
        @listener.run(self)
        @workers.each{|w| w.run(@listener.ractor)}
        @closer.run(@workers.map{|w| w.ractor})
      end

      def process(conn)
        Ractor.yield(conn, move: true)
      end

      def wait
        # listener, workers are using those outgoing to pass connections
        @closer.wait
      end
    end

    class AcceptProcessor < Base
      def initialize(workers, handler)
        @worker_num = workers
        @handler = handler
        @workers = workers.times.map{|i| Worker::Accepter.new(id: i, handler: @handler) }
      end

      def configure(listener:)
        @listener = listener
        @workers.each do |w|
          w.configure(listener.sock)
        end
      end

      def run
        @workers.each do |w|
          w.run
        end
        # TODO: connection closer
      end

      def wait
        @workers.each{|w| w.wait}
      end
    end
  end
end
