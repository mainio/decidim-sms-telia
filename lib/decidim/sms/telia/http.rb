# frozen_string_literal: true

module Decidim
  module Sms
    module Telia
      class Http
        def initialize(uri, authorization:, debug: false)
          @uri = URI.parse(uri)
          @authorization = authorization
          @debug = debug
        end

        def post(body = nil, **headers)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = uri.scheme == "https"
          http.set_debug_output($stdout) if debug
          response = nil
          http.start do
            request = Net::HTTP::Post.new(uri.request_uri)
            request["Authorization"] = authorization
            headers.each do |key, val|
              request[key] = val
            end
            request.body = body if body
            yield request if block_given?

            response = http.request(request)
          end

          response
        end

        private

        attr_reader :uri, :authorization, :debug
      end
    end
  end
end
