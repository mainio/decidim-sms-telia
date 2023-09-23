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
          # The cache expiry period is set according to the token validity
          # period at Telia's end which is actually "59999" but we use a bit
          # shorter time to avoid issues using a token at its expiration time.
          @token = Rails.cache.fetch("decidim/sms/telia/token", expires_in: 59_900.seconds) do
            # In case the token request does not return a token e.g. because of
            # invalid credentials, we need to return here in order to avoid an
            # infinite recursion.
            request || return
          end
          return @token if @token.valid?

          # Just in case, revoke the previous token before requesting a new
          # token.
          revoke(@token)

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
          # Clear the cached token because it is no longer valid after it is
          # revoked.
          Rails.cache.delete("decidim/sms/telia/token")

          response = Http.new(uri_for("revoke"), authorization: authorization_header, debug: debug).post do |req|
            req.set_form_data("token" => token.access_token)
          end
          response.code == "200"
        end

        def revoke_cached_token
          token = @token || Rails.cache.read("decidim/sms/telia/token")
          return false unless token

          @token = nil
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
