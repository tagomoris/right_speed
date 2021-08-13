# frozen_string_literal: true

require 'rack/builder'

require_relative 'worker/accepter'
require_relative 'worker/reader'

module RightSpeed
  module Processor
    def self.setup(ru:, worker_type:, workers:)
      app = Rack::Builder.parse_file(ru)
      app = if app.respond_to?(:call)
              app
            elsif app.is_a?(Array) && app[0].respond_to?(:call)
              # Rack::Builder returns [app, options] but options will be deprecated
              app[0]
            else
              raise "Failed to build Rack app from #{ru}: #{app}"
            end
      handler = Ractor.make_shareable(Handler.new(app))

      case worker_type
      when :read
        ReadProcessor.new(workers, handler)
      when :accept
        AcceptProcessor.new(workers, handler)
      else
        raise "Unknown worker type #{worker_type}"
      end
    end

    class Base
      def initialize(workers)
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

    class ReadProcessor < Base
      def initialize(workers, handler)
        @worker_num = workers
        @handler = handler
        @workers = workers.times.map{|i| Worker::Reader.new(id: i, handler: @handler)}
        @counter = 0
      end

      def configure(listener:)
        @listener = listener
      end

      def run
        @workers.each{|w| w.run}
        @listener.run(self)
      end

      def process(conn)
        current, @counter = @counter, @counter + 1
        @workers[current % @worker_num].process(conn)
      end

      def wait
        @workers.each{|w| w.wait}
      end
    end

    class AcceptProcessor < Base
      def initialize(workers, handler)
        @worker_num = workers
        @handler = handler
        @workers = workers.times.map{|i| Worker::Accepter.new(id: i, app: nil) } # TODO: app
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
      end

      def wait
        @workers.each{|w| w.wait}
      end
    end
  end
end
