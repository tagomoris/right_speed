# frozen_string_literal: true

require "uri"
require "rack"

module RightSpeed
  module RactorHelper
    def self.uri_hook
      # Use 3.1.0-dev!
    end

    def self.rack_hook
      ip_filter = Ractor.make_shareable(Rack::Request.ip_filter)
      overwrite_method(Rack::Request::Helpers, :trusted_proxy?) do |ip|
        ip_filter.call(ip)
      end
      overwrite_method(Rack::Request::Helpers, :query_parser, Rack::Utils.default_query_parser)
      overwrite_const(Rack::ShowExceptions, :TEMPLATE, Rack::ShowExceptions::TEMPLATE)
      freeze_all_constants(::Rack)
    end

    def self.freeze_all_constants(mojule, touch_list=[])
      touch_list << mojule
      mojule.constants.each do |const_name|
        const = begin
                  mojule.const_get(const_name)
                rescue LoadError
                  # ignore unloadable modules (autoload, probably)
                  nil
                end
        next unless const
        if const.is_a?(Module) && !touch_list.include?(const)
          # not freeze Module/Class because we're going to do monkey patching...
          freeze_all_constants(const, touch_list)
        else
          const.freeze
        end
      end
    end

    def self.overwrite_method(mojule, name, value=nil, &block)
      if block_given?
        mojule.define_method(name, Ractor.make_shareable(block))
      else
        v = Ractor.make_shareable(value)
        mojule.define_method(name, Ractor.make_shareable(->(){ v }))
      end
    end

    def self.overwrite_const(mojule, name, value)
      v = Ractor.make_shareable(value)
      mojule.const_set(name, value)
    end
  end
end
