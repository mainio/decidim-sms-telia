# frozen_string_literal: true

module Decidim
  module Sms
    module Telia
      class TokenManager
        def initialize(debug: false)
          @debug = debug
        end

        def generate_token
          uri = uri_for("token")
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.set_debug_output($stdout) if debug
          response = nil
          http.start do
            request = Net::HTTP::Post.new(uri.request_uri)
            request.set_form_data("grant_type" => "client_credentials")
            request["Authorization"] = authorization_header

            response = http.request(request)
          end

          @token = JSON.parse(response.body) if response.code == "200"
          @token["access_token"]
        end

        def revoke_token
          return unless @token

          uri = uri_for("revoke")
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.set_debug_output($stdout) if debug
          response = nil
          http.start do |http|
            request = Net::HTTP::Post.new(uri.request_uri)
            request.set_form_data("token" => @token["access_token"])
            request["Authorization"] = @credentials

            response = http.request(request)
          end
          @token = nil if response.code == "200"
          @token
        end

        private

        attr_reader :debug

        def uri_for(action)
          URI.parse("https://api.opaali.telia.fi/autho4api/v1/#{action}")
        end

        def authorization_header
          "Basic #{Base64.encode64(credentials.join(":")).strip}"
        end

        def credentials
          [
            Rails.application.secrets.telia[:username],
            Rails.application.secrets.telia[:password]
          ]
        end
      end
    end
  end
end
