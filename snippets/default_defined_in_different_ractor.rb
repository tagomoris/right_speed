require "pp"

class Foo
  attr_reader :map
  YAY = {foo: "bar"}
  def initialize(map, opts = {})
    @map = map.merge(opts)
  end
end

r = Ractor.new {
  Foo.new({yay: "yay"}, Foo::YAY).map
}

pp r.take
