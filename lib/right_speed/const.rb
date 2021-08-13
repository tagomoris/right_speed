# frozen_string_literal: true

require_relative "version"

module RightSpeed
  SOFTWARE_NAME = "RightSpeed #{VERSION} (#{RUBY_ENGINE} #{RUBY_VERSION}p#{RUBY_PATCHLEVEL} [#{RUBY_PLATFORM}])".freeze
  RACK_VERSION = Rack::VERSION.freeze
end
