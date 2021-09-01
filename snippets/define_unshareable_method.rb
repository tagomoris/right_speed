begin

  class Yo; end

  Yo.define_method(:yay){ :yo } # unisolated block
  r = Ractor.new {
    Yo.new.yay
    # RuntimeError: defined in a different Ractor
  }
  r.take


  yay = ->(){
    :yo
  }
  Ractor.make_shareable(yay)
  Yo.define_method(:yay, &yay)


  yay = ->(){
    :yo
  }.isolate
  Yo.define_method(:yay, &yay)

  # isolated_lambda_literal: true
  yay = ->(){ :yo }.dup # un-isolate



end

