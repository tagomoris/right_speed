# frozen_string_literal: true

require "socket"
require "logger"
require "webrick"

module RightSpeed
  class Server
    def initialize(port:, backlog:, workers:, worker_type:)
      @port = port
      @backlog = backlog
      @workers = workers
      @worker_type = worker_type

      @logger = nil
    end

    def logger # TODO: move to RightSpeed::Worker
      return @logger if @logger
      logger = Logger.new($stderr)
      logger.formatter = lambda {|severity, datetime, progname, msg| "[#{datetime}] #{msg}" }
      logger
    end

    def run
      # TODO: XXXXXXXXXXXXXXXXXXXXXXXXXX Something seems wrong now
      # The launch command stops immediately
      # $ bundle exec ruby bin/right_speed -p 8080
      logger.info "Starting RightSpeed server, type #{@worker_type}, workers: #{@workers}"
      ractors, finalizer = case @worker_type
                           when :read
                             run_read
                           when :accept
                             run_accept
                           else
                             raise "Unknown worker type #{@worker_type}"
                           end
      ractors.each{|r| r.take}
      finalizer.close rescue nil
    rescue => e
      logger.error "Error on the main loop\n#{e.full_message}"
    end

    def run_read
      workers = @workers.times.map{|i| Ractor.new(i, &method(:read_worker))}
      listener = Ractor.new(@port, @backlog, workers, &method(:accept_listener))
      ractors = workers + [listener]
      return ractors, nil
    end

    def run_accept
      sock = listener(@port, @backlog)
      workers = @workers.times.map{|i| Ractor.new(i, sock.dup, &method(:accept_worker))}
      finalizer = lambda { sock.close rescue nil }
      return workers, finalizer
    end

    def listener(listen_port, backlog)
      sock = TCPServer.open(listen_port)
      sock.listen(backlog)
      sock
    rescue => e
      logger.error "Unknown error on #listener\n#{e.full_message}"
    end

    def accept_worker(index, sock)
      while conn = sock.accept
        begin
          data = conn.read
          # TODO: process it
          logger.info "[read|#{index}] Data: #{data}"
        ensure
          conn.close rescue nil
        end
      end
    rescue => e
      logger.error "[read|#{index}] Error on worker#accept_worker\n#{e.full_message}"
    end

    def accept_listener(listen_port, backlog, workers)
      workers_num = workers.size
      begin
        sock = TCPServer.open(listen_port)
        sock.listen(backlog)
        counter = 0
        while conn = sock.accept
          worker = workers[counter % workers_num]
          worker.send(conn, move: true)
          counter += 1
        end
      ensure
        sock.close rescue nil
      end
    rescue => e
      logger.error "Error on a worker#listener\n#{e.full_message}"
    end

    def read_worker(index)
      # read and parse requests from sockets in Async manner (Fiber#scheduler ?)
      # https://github.com/fluent/fluentd/blob/master/lib/fluent/plugin/in_http.rb
      while conn = Ractor.receive
        begin
          data = conn.read
          # TODO: process it
          logger.info "[read|#{index}] Content: #{data}"
        ensure
          conn.close rescue nil
        end
      end
    rescue => e
      logger.error "[read|#{index}] Error on worker#read_worker\n#{e.full_message}"
    end
  end
end
