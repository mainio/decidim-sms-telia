# frozen_string_literal: true

module Decidim
  module Sms
    module Telia
      class Token
        def self.from(data)
          if data.is_a?(Net::HTTPResponse)
            token_data = JSON.parse(data.body)
            from(token_data.merge("issued_at" => Time.httpdate(data["Date"])))
          else
            # Note that the tokens are valid longer currently and the API
            # response contains the "expires_in" information but it has been
            # suggested by Telia that one token is only used for a maximum of 9
            # minutes at a time which is why we override this value.
            # expires_in = data["expires_in"]
            expires_in = 540
            new(data["access_token"], data["issued_at"] + expires_in.seconds)
          end
        end

        attr_reader :access_token, :expires_at

        def initialize(access_token, expires_at)
          @access_token = access_token
          @expires_at = expires_at
        end

        def authorization_header
          "Bearer #{access_token}"
        end

        def expired?
          expires_at < Time.zone.now
        end

        def valid?
          !expired?
        end

        def to_s
          access_token
        end
      end
    end
  end
end
