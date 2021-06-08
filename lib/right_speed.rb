# frozen_string_literal: true

require_relative "right_speed/version"

require "webrick"

module RightSpeed
  # https://docs.ruby-lang.org/en/master/Ractor.html

  # listen on the root Ractor

  # luanch Ractor workers
  # pass accepted sockets to workers
  server = Ractor.new do
    # read and parse requests from sockets in Async manner (Fiber#scheduler ?)
    # https://github.com/fluent/fluentd/blob/master/lib/fluent/plugin/in_http.rb

    # and then send responses
  end
end
