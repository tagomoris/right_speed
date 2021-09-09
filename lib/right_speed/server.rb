# frozen_string_literal: true

require "socket"
require "logger"
require "webrick"

require_relative "processor"
require_relative "listener"
require_relative "env"
require_relative "ractor_helper"

module RightSpeed
  CONFIG_HOOK_KEY = 'right_speed_config_hooks'

  class Server
    DEFAULT_HOST = "127.0.0.1"
    DEFAULT_PORT = 8080
    DEFAULT_WORKER_TYPE = :read
    DEFAULT_WORKERS = Env.processors
    DEFAULT_SCHEDULER_TYPE = :roundrobin

    AVAILABLE_WORKER_TYPES = [:read, :accept]
    AVAILABLE_LISTENER_TYPES = [:roundrobin, :fair]

    attr_reader :config_hooks

    def initialize(
          app:,
          host: DEFAULT_HOST,
          port: DEFAULT_PORT,
          workers: DEFAULT_WORKERS,
          worker_type: DEFAULT_WORKER_TYPE,
          scheduler_type: DEFAULT_SCHEDULER_TYPE,
          backlog: nil
        )
      @host = host
      @port = port
      @app = app
      @workers = workers
      @worker_type = worker_type
      @listener_type = case @worker_type
                       when :read then scheduler_type
                       else :listen
                       end
      @backlog = backlog
      @config_hooks = []
      @logger = nil
    end

    def run
      logger = RightSpeed.logger
      logger.info { "Start running with #{@workers} workers" }

      hooks = @config_hooks + (Ractor.current[RightSpeed::CONFIG_HOOK_KEY] || [])
      hooks.each do |hook|
        if hook.respond_to?(:call)
          hook.call
        end
      end

      RactorHelper.uri_hook
      RactorHelper.rack_hook

      begin
        processor = Processor.setup(app: @app, worker_type: @worker_type, workers: @workers)
        listener = Listener.setup(listener_type: @listener_type, host: @host, port: @port, backlog: nil)
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
