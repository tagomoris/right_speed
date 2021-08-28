module Yay
  def self.yay
    p @yay
  end

  def self.yay=(val)
    @yay = val
  end

  class << self
    def value
      p @yay
    end

    def value=(val)
      @yay = val
    end
  end
end

Yay.yay = "one"
Yay.yay

Yay.value = "two"
Yay.value
Yay.yay
