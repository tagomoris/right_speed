# frozen_string_literal: true
require "logger"
require "stringio"
require "http/parser"
require "rack"

require "pp"

require_relative "./const"

module RightSpeed
  class Handler
    def initialize(app)
      @app = app
    end

    def session(conn)
      Session.new(self, conn)
    end

    def process(session, client, request)
      # https://github.com/rack/rack/blob/master/SPEC.rdoc
      env = {
        'HTTP_VERSION' => request.http_version,
        'PATH_INFO' => request.path_info,
        'QUERY_STRING' => request.query_string,
        'REMOTE_ADDR' => client.addr,
        'REQUEST_METHOD' => request.http_method,
        'REQUEST_PATH' => request.path_info,
        'REQUEST_URI' => request.request_uri,
        'SCRIPT_NAME' => "",
        'SERVER_NAME' => client.server_addr,
        'SERVER_PORT' => client.server_port,
        'SERVER_PROTOCOL' => request.http_version,
        'SERVER_SOFTWARE' => RightSpeed::SOFTWARE_NAME,
        **request.headers_in_env_style,
        ### Rack specific keys
        'rack.version' => RightSpeed::RACK_VERSION,
        'rack.url_scheme' => 'http', # http or https, depending on the request URL.
        'rack.input' => request.body, # The input stream.
        'rack.errors' => nil, # The error stream.
        'rack.multithread' => false,
        'rack.multiprocess' => true,
        'rack.run_once' => false,
        'rack.hijack?' => false, # https://github.com/rack/rack/blob/master/SPEC.rdoc#label-Hijacking
        ### Optional Rack keys
        ## 'rack.session'
        # A hash like interface for storing request session data.
        # The store must implement:
        #   store(key, value) (aliased as []=); fetch(key, default = nil) (aliased as []);
        #   delete(key); clear; to_hash (returning unfrozen Hash instance);
        'rack.logger' => session.logger,
        # A common object interface for logging messages.
        # The object must implement:
        #   info(message, &block),debug(message, &block),warn(message, &block),error(message, &block),fatal(message, &block)
        ## 'rack.multipart.buffer_size'
        # An Integer hint to the multipart parser as to what chunk size to use for reads and writes.
        ## 'rack.multipart.tempfile_factory'
        # An object responding to #call with two arguments, the filename and content_type given for the multipart form field,
        # and returning an IO-like object that responds to #<< and optionally #rewind. This factory will be used to instantiate
        # the tempfile for each multipart form file upload field, rather than the default class of Tempfile.
      }
      pp(env: env)
      # status, headers, body = @app.call(env)
      Response.new(http_version: request.http_version, status_code: 200, headers: {"X-Yay" => "yay"}, body: ["Oooooooookay"])
    end

    class Client
      attr_reader :addr, :port, :server_addr, :server_port

      def initialize(conn)
        _, @port, _, @addr = conn.peeraddr
        _, @server_port, _, @server_addr = conn.addr
      end
    end

    class Request
      attr_reader :http_method, :http_version, :request_url, :headers, :body, :path_info, :query_string

      def initialize(client:, http_method:, http_version:, request_url:, headers:, body:)
        @client = client
        @http_method = http_method
        @http_version = "HTTP/" + http_version.map(&:to_s).join(".")
        @request_url = request_url
        @headers = headers
        @body = StringIO.new(body)

        @path_info, @query_string = request_url.split('?')
      end

      def request_uri
        "http://#{@client.server_addr}:#{@client.server_port}#{request_url}"
      end

      def headers_in_env_style
        headers = {}
        @headers.each do |key, value|
          headers["HTTP_" + key.gsub("-", "_").upcase] = value
        end
        headers
      end
    end

    class Response
      STATUS_MESSAGE_MAP = {
        200 => "OK",
      }.freeze

      attr_reader :body

      def initialize(http_version:, status_code:, headers:, body:)
        @http_version = http_version
        @status_code = status_code
        @status_message = STATUS_MESSAGE_MAP.fetch(status_code, "Unknown")
        @headers = headers
        @body = body
      end

      def status
        "#{@http_version} #{@status_code} #{@status_message}\r\n"
      end

      def headers
        @headers.map{|key, value| "#{key}: #{value}\r\n" }.join + "\r\n"
      end
    end

    class Session
      attr_reader :logger

      def initialize(handler, conn)
        @logger = RightSpeed.logger
        @handler = handler
        @conn = conn
        @client = Client.new(conn)

        # https://github.com/tmm1/http_parser.rb
        @parser = Http::Parser.new(self, default_header_value_type: :mixed)
        @reading = true
        @method = nil
        @url = nil
        @headers = nil
        @body = String.new
      end

      # TODO: implement handling of "Connection" and "Keep-Alive"
      # https://developer.mozilla.org/ja/docs/Web/HTTP/Headers/Connection
      # https://developer.mozilla.org/ja/docs/Web/HTTP/Headers/Keep-Alive

      def process
        while @reading
          @parser << @conn.readline
        end
      end

      def on_headers_complete(headers)
        @headers = headers
        @method = @parser.http_method
        @url = @parser.request_url
      end

      def on_body(chunk)
        @body << chunk
      end

      def on_message_complete
        @logger.debug {
          "complete to read the request, headers:#{@headers}, body:#{@body}"
        }
        request = Request.new(
          client: @client, http_method: @method, http_version: @parser.http_version,
          request_url: @url, headers: @headers, body: @body
        )
        response = @handler.process(self, @client, request)
        send_response(response)
        @reading = false
        @conn.close # TODO: keep-alive?
      end

      def send_response(response)
        @conn.write response.status
        @conn.write response.headers
        response.body.each do |part|
          @conn.write part
        end
      end
    end
  end
end
