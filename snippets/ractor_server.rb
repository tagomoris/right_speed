require 'socket'

worker_num = 2

sock = TCPServer.new("127.0.0.1", 8228)
workers = worker_num.times.map do |i|
  Ractor.new(i) do |index|
    while conn = Ractor.receive
      begin
        data = conn.readline
        conn.write "HTTP/1.1 200 OK\r\n\r\n"
        conn.close
        conn = nil
      rescue => e
        p "Worker|#{index} #{e.full_message}"
      end
    end
  end
end

p "Starting a listener"
listener = Ractor.new(sock, workers) do |sock, workers|
  workers_num = workers.size
  i = 0
  begin
    while conn = sock.accept
      worker = workers[i % workers_num]
      worker.send(conn, move: true)
      i += 1
    end
  rescue => e
    p "Listener| #{e.full_message}"
  end
end

workers.each{|w| w.take}
p "End"
