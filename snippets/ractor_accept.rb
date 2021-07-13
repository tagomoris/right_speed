require 'socket'

try_times = 10
worker_num = 2

listener = TCPServer.new("127.0.0.1", 8228)
listener.listen(100)
workers = worker_num.times.map do |i|
  Ractor.new(i, listener.dup) do |index, sock|
    while conn = sock.accept
      begin
        data = conn.read
        p "Worker|#{index} Data: #{data}"
        conn.close
      rescue => e
        p "Worker|#{index} #{e.full_message}"
      end
    end
  rescue => e
    $stderr.puts "Error, worker#{index}: #{e.full_message}"
  end
end

p "Starting a sender"
sender = Ractor.new(try_times) do |tries|
  tries.times.each do
    s = TCPSocket.new("127.0.0.1", 8228)
    s.write("yay")
  ensure
    s.close rescue nil
  end
end

sender.take
workers.each{|w| w.take}
p "End"
