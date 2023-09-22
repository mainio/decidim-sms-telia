# frozen_string_literal: true

module Decidim
  module Sms
    module Telia
      class TokenManager
        def initialize(debug: false)
          @debug = debug
        end

        def generate_token
          response = Http.new(uri_for("token"), authorization: authorization_header, debug: debug).post do |request|
            request.set_form_data("grant_type" => "client_credentials")
          end

          @token = JSON.parse(response.body) if response.code == "200"
          @token["access_token"] if @token
        end

        def revoke_token
          return unless @token

          response = Http.new(uri_for("revoke"), authorization: authorization_header, debug: debug).post do |request|
            request.set_form_data("token" => @token["access_token"])
          end
          @token = nil if response.code == "200"
          @token
        end

        private

        attr_reader :debug

        def uri_for(action)
          "https://api.opaali.telia.fi/autho4api/v1/#{action}"
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
