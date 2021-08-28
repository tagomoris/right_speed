class AtomicReference
  def initialize(value)
    @value = value
    @mutex = Ractor.make_shareable(Mutex.new)
  end

  def get
    @mutex.synchronize { @value }
  end

  def set(value)
    @mutex.synchronize do
      @value = value
    end
  end
end

module Yay
  VALUE = Ractor.make_shareable(AtomicReference.new("yay"))

  def self.value
    VALUE.get
  end

  def self.value=(value)
    VALUE.set(value)
  end
end

r1 = Ractor.new do
  1000.times do |i|
    Yay.value = "Yay#{i}"
    Yay.value
  end
  Yay.value
end

r2 = Ractor.new do
  1000.times do |i|
    Yay.value = "Boo#{i}"
    Yay.value
  end
  Yay.value
end

p(r1: r1.take, r2: r2.take)
