require "test/unit"
include Test::Unit::Assertions

require "error_highlight"

custom_formatter = Object.new
def custom_formatter.message_for(spot)
  "\n\n" + spot.inspect
end
ErrorHighlight.formatter = custom_formatter

class ExceptionTest < Test::Unit::TestCase
  def test_yay
    assert_raise(NoMethodError) do
      begin
        Ractor.new { 1.time {} }.take
      rescue Ractor::RemoteError => e
        p(here: "rescue", e: "#{e}", cause: "#{e.cause}", r: "#{e.ractor}")
        raise e.cause
      end
    end
  end
end
