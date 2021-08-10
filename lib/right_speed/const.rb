# frozen_string_literal: true

require_relative "version"

module RightSpeed
  SOFTWARE_NAME = "Rightspeed #{VERSION} (#{RUBY_ENGINE} #{RUBY_VERSION}p#{RUBY_PATCHLEVEL} [#{RUBY_PLATFORM}])".freeze
  RACK_VERSION = Rack::VERSION.freeze
end
