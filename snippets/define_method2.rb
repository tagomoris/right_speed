class Yay
end

x = 1
pr = ->(){ x + 3 }
Ractor.make_shareable(pr)
Yay.define_method(:yay, &pr)

pr2 = Yay.new.method(:yay).to_proc # this proc is not isolated - the state is not saved
Ractor.make_shareable(pr2) # without this, raise an error
Yay.define_method(:foo, &pr2)

r1 = Ractor.new { Yay.new.foo }
p(r1: r1.take)
