module Rack
  module Client
    class Base
      extend Forwardable

      def_delegator :@app, :call

      def initialize(app)
        @app = app
      end

      %w[ options get head post put delete trace connect ].each do |method|
        eval <<-RUBY, binding, __FILE__, __LINE__ + 1
          def #{method}(url, headers = {}, body = nil, &block)
            request('#{method.upcase}', url, headers, body, &block)
          end
        RUBY
      end

      def request(method, url, headers = {}, body = nil)
        if block_given?
          call(build_env(method.upcase, url, headers, body)) {|tuple| yield *tuple }
        else
          return *call(build_env(method.upcase, url, headers, body))
        end
      end

      def build_env(request_method, url,  headers = {}, body = nil)
        env = Headers.new(headers).to_env

        env.update 'REQUEST_METHOD' => request_method

        env['CONTENT_TYPE'] ||= 'application/x-www-form-urlencoded'

        uri = URI.parse(url)

        path_info = uri.path.empty? ? '/' : uri.path
        path_info += '?' + uri.query unless uri.query.nil? || uri.query.empty?

        env.update 'PATH_INFO'    => path_info
        env.update 'REQUEST_URI'  => uri.to_s
        env.update 'SERVER_NAME'  => uri.host.to_s
        env.update 'SERVER_PORT'  => uri.port.to_s
        env.update 'SCRIPT_NAME'  => ''
        env.update 'QUERY_STRING' => uri.query.to_s

        input = case body
                when nil        then StringIO.new
                when String     then StringIO.new(body)
                end

        env.update 'rack.input'         => input
        env.update 'rack.errors'        => StringIO.new
        env.update 'rack.url_scheme'    => uri.scheme || 'http'
        env.update 'rack.version'       => Rack::VERSION
        env.update 'rack.multithread'   => true
        env.update 'rack.multiprocess'  => true
        env.update 'rack.run_once'      => false

        env.update 'HTTPS'  => env["rack.url_scheme"] == "https" ? "on" : "off"

        env
      end
    end
  end
end
