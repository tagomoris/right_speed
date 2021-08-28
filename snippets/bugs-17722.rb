class A
  m = proc { |val|
    instance_variable_set(:"@#{v}", val)
  }
  Ractor.make_shareable(m)
  define_method :"a=", &m
  attr_reader :a

  def initialize(opts)
    opts.each do |k, v|
      puts "#{k} = #{v}"
      __send__(:"#{k}=", v)
    end
  end
end

ractors = []

DEFAULTS = { a: 1 }
Ractor.make_shareable(DEFAULTS)

1.times do
  ractors << Ractor.new do
    a = A.new(DEFAULTS)
  end
end
ractors.map(&:take)
