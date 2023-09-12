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

        def initialize(phone_number, code)
          @phone_number = phone_number
          @code = code

          @authorization ||= Rails.application.secrets.telia[:telia_authorization]
          @telia_sender ||= Rails.application.secrets.telia[:telia_sender_address]
          @telia_sender_name ||= Rails.application.secrets.telia[:telia_sender_name]
        end

        def deliver_code
          track_delivery do |delivery|
            request = create_message!(delivery.callback_data)

            response = JSON.parse(http.request(request))

            if response
              delivery.update!(
                to: @phone_number,
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

        def client
          @client ||= ::Telia::REST::Client.new(@account_sid, @auth_token)
        end

        def create_message!(callback_data)
          uri = URI.parse("https://api.opaali.telia.fi/production/messaging/v1/outbound/#{@telia_sender}/requests")

          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true

          request = ::Net::HTTP::Post.new(uri.path, "Content-Type" => "application/json")

          request["Authorization"] = "Bearer #{@authorization}"

          request.body = {
            outboundMessageRequest: {
              address: @phone_number,
              senderAddress: @sender_address,
              outboundSMSBinaryMessage: {
                message: @code
              },
              senderName: @telia_sender_name,
              receiptRequest: {
                notifyURL: options[:notify_url],
                notificationFormat: "JSON",
                callbackData: callback_data
              }
            }
          }.to_json
          request
        end

        def track_delivery
          yield Delivery.create(
            from: @telia_sender,
            to: @phone_number,
            status: ""
          )
        end
      end
    end
  end
end
