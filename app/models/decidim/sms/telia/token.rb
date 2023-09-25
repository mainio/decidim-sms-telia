# frozen_string_literal: true

module Decidim
  module Sms
    module Telia
      # The data store for a API tokens. Note that only one token is valid at
      # a time for given credentials, so these cannot be scoped e.g. to
      # organization. With the same credentials, only one token can be utilized
      # at a time.
      class Token < Telia::ApplicationRecord
        def self.from(data)
          if data.is_a?(Net::HTTPResponse)
            token_data = JSON.parse(data.body)
            from(token_data.merge("issued_at" => Time.httpdate(data["Date"])))
          else
            transaction do
              # Destroy all previous tokens because when a new token is issued,
              # the old tokens are automatically invalidated at the API side.
              destroy_all

              # Note that the tokens are valid longer currently and the API
              # response contains the "expires_in" information but it has been
              # suggested by Telia that one token is only used for a maximum of
              # 9 minutes at a time which is why we override this value.
              # expires_in = data["expires_in"]
              expires_in = 540
              create!(
                access_token: data["access_token"],
                issued_at: data["issued_at"],
                expires_at: data["issued_at"] + expires_in.seconds
              )
            end
          end
        end

        def self.current
          valid.order(id: :desc).first
        end

        scope :valid, -> { where("expires_at > ?", Time.zone.now) }
        scope :expired, -> { where("expires_at <= ?", Time.zone.now) }

        def authorization_header
          "Bearer #{access_token}"
        end

        def expired?
          expires_at <= Time.zone.now
        end

        def to_s
          access_token
        end
      end
    end
  end
end
