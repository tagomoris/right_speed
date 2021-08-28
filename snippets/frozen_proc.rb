x = 1

p1 = ->(){ x + 1 }
p2 = ->(){ x + 2 }
p3 = ->(){ x + 3 }

p2.freeze
Ractor.make_shareable(p3)

x = 0

pp(p1: p1.call, p2: p2.call, p3: p3.call)
pp(p1f: p1.frozen?, p2f: p2.frozen?, p3f: p3.frozen?)

VALUE = "yay"
Ractor.make_shareable(VALUE)

pp(value: VALUE, frozen: VALUE.frozen?)


HASH = {key: "value"}
Ractor.make_shareable(HASH)

pp(hash: HASH, fronzen: HASH[:key].frozen?)

y = "yay"
p4 = ->(){ y + "4" }
Ractor.make_shareable(p4)

pp(p4: p4.call) # error!
