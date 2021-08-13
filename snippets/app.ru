# frozen_string_literal: true
require 'pp'

class MyApp
  def call(env)
    pp(ractor: Ractor.current.object_id, env: env)
    [200, {'Content-Type' => 'text/html', 'Content-Length' => 2.to_s}, ['OK']]
  end
end

run MyApp.new
