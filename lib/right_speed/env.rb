# frozen_string_literal: true
require "concurrent"

module RightSpeed
  module Env
    def self.processors
      Concurrent.processor_count
    end
  end
end
