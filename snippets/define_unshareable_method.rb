module Yo
  def self.yay
    "yay"
  end
end

Yo.define_singleton_method(:yay) do
  "yo"
end

p(yo: Yo.yay)

r = Ractor.new { Yo.yay }
p(yo: r.take)
