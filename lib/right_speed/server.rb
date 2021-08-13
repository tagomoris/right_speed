# frozen_string_literal: true

require "socket"
require "logger"
require "webrick"

require_relative "processor"
require_relative "listener"

module RightSpeed
  class Server
    def initialize(port:, ru:, workers:, worker_type:, backlog:)
      @port = port
      @ru = ru
      @workers = workers
      @worker_type = worker_type
      @listener_type = case @worker_type
                       when :read
                         :accept
                       else
                         :listen
                       end
      @backlog = backlog
      @logger = nil
    end

    def run
      begin
        processor = Processor.setup(ru: @ru, worker_type: @worker_type, workers: @workers)
        listener = Listener.setup(listener_type: @listener_type, port: @port, backlog: @backlog)
        processor.configure(listener: listener)
        processor.run
        listener.wait
        processor.wait
      ensure
        listener.stop rescue nil
        processor.stop rescue nil
      end
    end
  end
end
