begin

  # Usual Proc
  x = 1
  p1 = ->() { x + 2 }

  p p1.call #=> 3

  x = 5
  p p1.call #=> 7


  #


  # Isolated Proc
  x = 1
  p2 = ->() { x + 2 }
  Ractor.make_shareable(p2)
  # p2 is isolated

  p p2.call #=> 3

  x = 5
  p p2.call #=> 3 (!)


  ###################

  s = "Yaaaaaaay"
  p3 = ->(){ s.upcase }
  Ractor.make_shareable(p3)
  # Ractor::IsolationError
  # p3 is referring unshareable objects

  s = "Boooooooo".freeze
  p4 = ->(){ s.upcase }
  Ractor.make_shareable(p4)
  # OK

end
