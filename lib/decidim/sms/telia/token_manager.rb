# frozen_string_literal: true

module Decidim
  module Sms
    module Telia
      class TokenManager
        def initialize(debug: false)
          @debug = debug
        end

        # Fetches a valid token either from cache or by requesting it from the
        # server if there is no cached token or the token has expired.
        def fetch
          token ||= Token.current || request

          # If the token is not set, it means that the token endpoint response
          # was not expected and probably the credentials are incorrect.
          return unless token
          return token unless token.expired?

          # Just in case, revoke the previous token before requesting a new
          # token.
          revoke(token)

          # Re-fetch a new token and cache it.
          fetch
        end

        def request
          response = Http.new(uri_for("token"), authorization: authorization_header, debug: debug).post do |req|
            req.set_form_data("grant_type" => "client_credentials")
          end
          return if response.code != "200"

          # Suggestion from Telia is to have a short delay before utilizing this
          # token against the messaging API. It may take a while for the token
          # to become active.
          sleep 2

          Token.from(response)
        end

        def revoke(token)
          response = Http.new(uri_for("revoke"), authorization: authorization_header, debug: debug).post do |req|
            req.set_form_data("token" => token.access_token)
          end
          token.destroy
          response.code == "200"
        end

        def revoke_cached_token
          token = Token.current
          return false unless token

          revoke(token)
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
