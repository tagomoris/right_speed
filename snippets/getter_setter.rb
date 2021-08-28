module Yay
  DEFAULT_VALUE = 1

  def self.value
    DEFAULT_VALUE
  end

  def self.value=(value)
    provider = proc { value }
    Ractor.make_shareable(provider) if defined?(Ractor)
    define_singleton_method(:value, &provider)
  end
end

pp(here: :before, value: Yay.value)

Yay.value = 30

pp(here: :after, value: Yay.value)
