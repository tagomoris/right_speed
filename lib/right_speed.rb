# frozen_string_literal: true

require_relative "right_speed/version"
require_relative "right_speed/env"

require "socket"
require "webrick"

module RightSpeed
  DEFAULT_PORT = 8228
  DEFAULT_WORKERS = Env.processors
  DEFAULT_BACKLOG = 1000

  WORKER_TYPES = {
    # accept: :accept_worker,
    read: :read_worker,
  }

  def self.main(worker_type: :read)
    raise "Unknown worker type: #{worker_type}" unless WORKER_TYPES.keys.include?(worker_type)
    worker_method_name = WORKER_TYPES.fetch(worker_type)

    @workers = DEFAULT_WORKERS.times.map{|i| Ractor.new(i, &method(worker_method_name))}
    @listener = Ractor.new(DEFAULT_PORT, DEFAULT_BACKLOG, @workers, &method(:listener))
    [*@workers, @listener].each do |r|
      r.take
    end
  end

  def self.listener(listen_port, backlog, workers)
    puts "L: started"
    workers_num = workers.size
    puts "L: listening"
    sock = TCPServer.open(listen_port)
    sock.listen(backlog)
    counter = 0
    puts "L: accepting connections"
    while conn = sock.accept
      puts "L: accepted"
      worker = workers[counter % workers_num]
      worker.send(conn, move: true)
      puts "L: sent a connection to worker \##{counter % workers_num}"
      counter += 1
    end
    puts "L: finishing"
  rescue => e
    puts "L: rescue #{e}"
  end

  def self.accept_worker(index)
    raise "booooooooooo"
  end

  def self.read_worker(index)
    puts "W[#{index}]: started"
    # read and parse requests from sockets in Async manner (Fiber#scheduler ?)
    # https://github.com/fluent/fluentd/blob/master/lib/fluent/plugin/in_http.rb
    while conn = Ractor.receive
      puts "W[#{index}]: receive a connection"
      data = conn.read
      puts "W[#{index}]: ===========\n#{data}\n================"
      conn.close rescue nil
    end
    puts "W[#{index}]: finishing"
  rescue => e
    puts "W[#{index}]: rescue #{e}"
  end
end

RightSpeed.main
