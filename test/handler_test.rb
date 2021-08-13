# frozen_string_literal: true

require "test_helper"
require "json"
require "socket"
require "net/http"
require "uri"

class HandlerTest < Test::Unit::TestCase
  App = lambda do |env|
    env['rack.input'] = env['rack.input'].read
    json = env.to_json
    [200, {'content-length' => json.size, 'content-type' => 'application/json'}, [json]]
  end

  def get(session, path, headers)
    session.get(path, headers)
  end

  def put(session, path, headers, body)
    session.put(path, body, headers)
  end

  def setup
    @handler = RightSpeed::Handler.new(App)
    @server = TCPServer.new("127.0.0.1", 0) # any ports available
    @server.listen(1) # backlog just 1 for the test request
    @port = @server.addr[1]
    @writer = lambda do |http_method, path, headers={}, body=nil|
      block = case http_method
              when :get
                ->(session){ get(session, path, headers) }
              when :put
                ->(session){ put(session, path, headers, body) }
              else
                raise "boo"
              end
      Thread.new do
        Net::HTTP.start("127.0.0.1", @port) do |session|
          block.call(session)
        end
      end
    end
  end

  test 'process and get response' do
    t = @writer.call(:get, '/path/of/endpoint?query=&key=value', {"user-agent" => "testing"})
    conn = @server.accept
    @handler.session(conn).process

    res = t.value
    assert_equal("200", res.code)
    assert_equal(2, res.size)
    assert_equal("application/json", res["Content-Type"])

    json = JSON.parse(res.body)
    assert_equal('/path/of/endpoint', json["PATH_INFO"])
    assert_equal('query=&key=value', json["QUERY_STRING"])
    assert(json["SERVER_SOFTWARE"].start_with?("RightSpeed #{RightSpeed::VERSION} "), json["SERVER_SOFTWARE"])
    assert_equal("http://127.0.0.1:#{@port}/path/of/endpoint?query=&key=value", json["REQUEST_URI"])
    assert_equal("testing", json["HTTP_USER_AGENT"])
    assert_equal("", json["rack.input"])
  end
end
