# frozen_string_literal: true

# A Service to send SMS to Telia provider to make capability of sending sms with Telia gateway
module Decidim
  module Sms
    class GatewayError < StandardError
      attr_reader :error_code

      def initialize(message = "Gateway error", error_code = :unknown)
        @error_code = error_code
        super(message)
      end
    end

    module Telia
      class TeliaGatewayError < GatewayError
        def initialize(message = "Gateway error", error_code = 0)
          super(message, telia_error(error_code))
        end

        private

        def telia_error(telia_code)
          case telia_code
          when 21_211
            :invalid_to_number
          when 21_408
            :invalid_geo_permission
          when 21_606
            :invalid_from_number
          else
            # Please check the logs for more information on these errors.
            :unknown
          end
        end
      end

      class Gateway
        include TokenGenerator

        attr_reader :phone_number, :code

        def initialize(phone_number, code, organization: nil)
          @phone_number = phone_number
          @code = code
          @organization = organization
          @account_sid ||= Rails.application.secrets.telia[:telia_account_sid]
          @auth_token ||= Rails.application.secrets.telia[:telia_auth_token]
          @telia_sender ||= Rails.application.secrets.telia[:telia_sender]
        end

        def deliver_code
          track_delivery do |delivery|
            create_message!

            response = client.http_client.last_response

            if response
              delivery.update!(
                to: response.body["to"],
                sid: response.body["sid"],
                status: response.body["status"]
              )
            end
          end

          true
        rescue ::Telia::REST::RestError => e
          Rails.logger.error "Telia::REST::RestError -- Telia failed to deliver the code"
          Rails.logger.error "Telia Error: #{e.code}"
          Rails.logger.error e.message
          Rails.logger.error e.backtrace.join("\n")

          raise TeliaGatewayError.new(e.message, e.code)
        end

        private

        attr_reader :organization

        def client
          @client ||= ::Telia::REST::Client.new(@account_sid, @auth_token)
        end

        def create_message!
          options = {}.tap do |opt|
            opt[:body] = @code
            opt[:from] = @telia_sender
            opt[:to] = @phone_number
            if @organization
              opt[:status_callback] = Decidim::EngineRouter.new(
                "decidim_sms_telia",
                { host: @organization.host }
              ).delivery_url(token: generate_token(@organization.host))
            end
          end
          client.messages.create(**options)
        end

        def track_delivery
          yield Delivery.create(
            from: @telia_sender,
            to: @phone_number,
            body: @code,
            status: ""
          )
        end
      end
    end
  end
end
