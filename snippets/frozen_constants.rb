
  class Yay
    VALUE1 = "yay" # Bad
    VALUE2 = {yay: "yay"} # Bad
    VALUE3 = {yay: "yay"}.freeze # Bad!!!
    
    VALUE4 = "yay".freeze # OK
    VALUE5 = Ractor.make_shareable({yay: "yay"}) # OK

    # frozen_string_literal: true
    VALUE6 = "yay"               # OK
    VALUE7 = {yay: "yay"}.freeze # OK
  end

r1 = Ractor.new {
  p(yay: Yay::VALUE5)
}

begin
  r1.take
rescue => e
  puts "Exception #{e}"
end

