require "json"
r1 = Ractor.new {
  JSON.dump({yay: 3})
}

pp(r1: r1.take)
