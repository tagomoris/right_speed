# frozen_string_literal: true

require "test_helper"

class RightSpeedTest < Test::Unit::TestCase
  test "VERSION" do
    assert do
      ::RightSpeed.const_defined?(:VERSION)
    end
  end
end
