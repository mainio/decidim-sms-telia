# frozen_string_literal: true

module Decidim
  module Sms
    module Telia
      class TokenManager
        def initialize(debug: false)
          @token_uri = parse_uri_for("token")
          @revoke_uri = parse_uri_for("revoke")
          @credentials = generate_credentials
          @debug = debug
        end

        def generate_token
          http = Net::HTTP.new(@token_uri.host, @token_uri.port)
          http.use_ssl = true
          http.set_debug_output($stdout) if debug
          response = nil
          http.start do
            request = Net::HTTP::Post.new(@token_uri.request_uri)
            request.set_form_data("grant_type" => "client_credentials")
            request["Authorization"] = @credentials

            response = http.request(request)
          end

          @token = JSON.parse(response.body) if response.code == "200"
          @token["access_token"]
        end

        def revoke_token
          return unless @token

          http = Net::HTTP.new(@revoke_uri.host, @revoke_uri.port)
          http.use_ssl = true
          http.set_debug_output($stdout) if debug
          response = nil
          http.start do |http|
            request = Net::HTTP::Post.new(@revoke_uri.request_uri)
            request.set_form_data("token" => @token["access_token"])
            request["Authorization"] = @credentials

            response = http.request(request)
          end
          @token = nil if response.code == "200"
          @token
        end

        private

        attr_reader :debug

        def parse_uri_for(action)
          URI.parse("https://api.opaali.telia.fi/autho4api/v1/#{action}")
        end

        def generate_credentials
          "Basic #{Base64.encode64(credentials_hash.values.join(":")).strip}"
        end

        def credentials_hash
          {
            uname: Rails.application.secrets.telia[:telia_credentials_uname],
            pword: Rails.application.secrets.telia[:telia_credentials_pword]
          }
        end
      end
    end
  end
end
