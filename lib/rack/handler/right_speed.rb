# frozen_string_literal: true

require "right_speed/server"

module Rack
  module Handler
    class RightSpeed
      def self.run(app, **options)
        environment  = ENV['RACK_ENV'] || 'development'
        default_host = environment == 'development' ? '127.0.0.1' : '0.0.0.0'

        host = options.delete(:Host) || default_host
        port = options.delete(:Port) || 8080
        workers = options.delete(:Workers) || ::RightSpeed::Env.processors
        server = ::RightSpeed::Server.new(app: app, host: host, port: port, workers: workers)

        yield server if block_given?

        server.run
      end

      def self.valid_options
        environment  = ENV['RACK_ENV'] || 'development'
        default_host = environment == 'development' ? '127.0.0.1' : '0.0.0.0'
        {
          "Host=HOST" => "Hostname to listen on (default: #{default_host})",
          "Port=PORT" => "Port to listen on (default: 8080)",
          "Workers=NUM" => "Number of workers (default: #{::RightSpeed::Env.processors})",
        }
      end
    end

    register :right_speed, ::Rack::Handler::RightSpeed
  end
end
