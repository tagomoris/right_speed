# frozen_string_literal: true

require_relative "right_speed/version"
require_relative "right_speed/env"

require "socket"
require "webrick"
require "logger"
require "getoptlong"

module RightSpeed
  DEFAULT_PORT = 8228
  DEFAULT_WORKERS = Env.processors
  DEFAULT_BACKLOG = 1000

  COMMAND_OPTIONS = [
    ['--worker-type', GetoptLong::REQUIRED_ARGUMENT],
    ['--help', GetoptLong::NO_ARGUMENT],
  ]

  def self.getlogger
    logger = Logger.new($stderr)
    logger.formatter = lambda {|severity, datetime, progname, msg| "[#{datetime}] #{msg}" }
    logger
  end

  LOG = RightSpeed.getlogger

  def self.start
    optparse = GetoptLong.new
    optparse.set_options(*COMMAND_OPTIONS)
    worker_type = :read
    optparse.each_option do |name, value|
      case name
      when '--worker-type'
        worker_type = value.to_sym
      when '--help'
        show_help
      else
        LOG.error "Unknown option: #{name}"
        show_help
      end
    end
    main(worker_type: worker_type)
  end

  def self.show_help
    STDERR.puts <<~EOS
      Usage: right_speed [options]

      OPTIONS
        --worker-type TYPE    The type of workers, available options are read/accept (default: read)
        --help                Show this message
    EOS
    exit
  end

  def self.main(worker_type: :read)
    finalizer = nil
    ractors = case worker_type
              when :read
                workers = DEFAULT_WORKERS.times.map{|i| Ractor.new(getlogger, i, &method(:read_worker))}
                listener = Ractor.new(getlogger, DEFAULT_PORT, DEFAULT_BACKLOG, workers, &method(:accept_listener))
                # workers = DEFAULT_WORKERS.times.map{|i| Ractor.new(i, &method(:read_worker))}
                # listener = Ractor.new(DEFAULT_PORT, DEFAULT_BACKLOG, workers, &method(:accept_listener))
                [*workers, listener]
              when :accept
                sock = listener(DEFAULT_PORT, DEFAULT_BACKLOG)
                workers = DEFAULT_WORKERS.times.map{|i| Ractor.new(getlogger, i, sock.dup, &method(:accept_worker))}
                # workers = DEFAULT_WORKERS.times.map{|i| Ractor.new(i, sock.dup, &method(:accept_worker))}
                finalizer = lambda { sock.close rescue nil }
                workers
              else
                raise "unknown worker type #{worker_type}"
              end
    ractors.each{|r| r.take}
    finalizer.close rescue nil
  rescue => e
    LOG.error "Error on the main loop\n#{e.full_message}"
  end

  def self.listener(listen_port, backlog)
    sock = TCPServer.open(listen_port)
    sock.listen(backlog)
    sock
  rescue => e
    LOG.error "Unknown error on #listener\n#{e.full_message}"
  end

  def self.accept_worker(logger, index, sock)
  # def self.accept_worker(index, sock)
    ### logger = getlogger
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

  def self.accept_listener(logger, listen_port, backlog, workers)
  # def self.accept_listener(listen_port, backlog, workers)
    ### logger = getlogger
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

  def self.read_worker(logger, index)
  # def self.read_worker(index)
    ### logger = getlogger
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

RightSpeed.start
