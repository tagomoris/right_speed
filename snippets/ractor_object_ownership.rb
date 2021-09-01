listener = Ractor.new do
  sleep 3
  "listener"
end

workers = 5.times.map do |i|
  Ractor.new(i, listener) do |num, listener|
    3.times do |n|
      sleep 1
      Ractor.yield "worker#{num}, num:#{n}"
    end
    Ractor.yield :closing
    "worker#{num}, listener:#{listener}"
  end
end

closer = Ractor.new(workers.dup) do |workers|
  while workers.size > 0
    r, obj = Ractor.select(*workers, move: true)
    if obj == :closing
      workers.delete(r)
    else
      p(here: :in_closer, value: obj)
    end
  end
  "closer"
end

workers.each do |worker|
  p(here: :worker, obj: worker, value: worker.take)
end

p(here: :listener, obj: listener, value: listener.take)
p(here: :closer, obj: closer, value: closer.take)
