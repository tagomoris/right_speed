class Boo
  def value
    "a"
  end
end

module Wow
  def value
    "b"
  end
end

Boo.prepend(Wow)

p(boo: Boo.new.value)

r = Ractor.new do
  Boo.new.value
end

p(ractorX: r.take) # Yay!

class Foo
  def value
    "a"
  end
end

a = "b".freeze
Foo.define_method(:value, Ractor.make_shareable(Proc.new { a }))

p(foo: Foo.new.value)

r = Ractor.new do
  Foo.new.value
end

p(ractorY: r.take)


class Yay
  def value
    "a"
  end
end

Yay.define_method(:value) { "b" }

p(yay: Yay.new.value) #=> "b"

r = Ractor.new do
  Yay.new.value
  # snippets/define_method.rb:12:in `block in <main>': defined in a different Ractor (RuntimeError)
end

p(ractor: r.take)
