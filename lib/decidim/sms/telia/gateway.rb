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
      class TeliaPolicyError < GatewayError
        def initialize(message = "Gateway error", error_code = 0)
          super(message, telia_error(error_code))
        end

        private

        def telia_error(telia_code)
          case telia_code
          when "POL3003"
            :server_busy
          when "POL3101"
            :invalid_to_number
          when "POL3006"
            :destination_whitelist
          when "POL3007"
            :destination_blacklist
          else
            # Please check the logs for more information on these errors.
            :unknown
          end
        end
      end

      class Gateway
        attr_reader :phone_number, :code, :organization, :telia_sender, :telia_sender_name

        def initialize(phone_number, code, organization: nil, queued: false)
          @phone_number = "tel:#{phone_number}"
          @code = code
          @organization ||= organization
          @telia_sender ||= "tel:#{Rails.application.secrets.telia[:telia_sender_address]}"
          @telia_sender_name ||= Rails.application.secrets.telia[:telia_sender_name]
          @queued = queued
        end

        def deliver_code
          track_delivery do |delivery|
            response, status = create_message!(delivery.callback_data)
            resource_url = response&.dig("resourceReference", "resourceURL")

            delivery.update!(
              resource_url: resource_url,
              status: status
            )
          end

          true
        end

        private

        def create_message!(callback_data)
          authorization = token_instance.generate_token
          send_uri = set_send_uri
          response = Net::HTTP.start(send_uri.host, send_uri.port, use_ssl: true) do |http|
            request = Net::HTTP::Post.new(send_uri.request_uri)
            request.body = request_body(callback_data)
            request["Authorization"] = "Bearer #{authorization}"
            request["Accept"] = "application/json"
            request["Content-Type"] = "application/json"

            http.request(request)
          end
          token_instance.revoke_token
          if %w(200 201 202).include?(response.code)
            [parse_json(response.body), "sent"]
          else
            handle_policy_exception(parse_json(response.body))
          end
        end

        def parse_json(response)
          JSON.parse(response)
        end

        def token_instance
          TokenManager.new
        end

        def request_body(callback_data)
          {
            "outboundMessageRequest" => {
              "address" => [phone_number],
              "senderName" => telia_sender_name,
              "senderAddress" => telia_sender,
              "outboundSMSTextMessage" => { "message" => code },
              "receiptRequest" => {
                "notifyURL" => Decidim::EngineRouter.new(
                  "decidim_sms_telia",
                  { host: organization.host }
                ).delivery_url(callback_data: callback_data),
                "notificationFormat" => "JSON"
              }
            }
          }.to_json
        end

        def set_send_uri
          URI.parse("https://api.opaali.telia.fi/#{mode}/messaging/v1/outbound/#{CGI.escape(telia_sender)}/requests")
        end

        def mode
          Rails.env.development? ? "sandbox" : "production"
        end

        def track_delivery
          yield Delivery.create(
            from: remove_prefix(telia_sender),
            to: remove_prefix(phone_number),
            status: "initiated"
          )
        end

        def remove_prefix(phone)
          phone.split("tel:").last
        end

        def handle_policy_exception(response)
          exception_code = response.dig("requestError", "policyException", "messageId")
          exeption_text = response.dig("requestError", "policyException", "variables")

          log_policy_error(policy_error(exeption_text), exception_code)

          enque_message_delivery if exception_code == "POL3003"
          raise TeliaPolicyError.new("Telia Policy error", exception_code)
          # raise TeliaPolicyError.new("Telia Policy error", exception_code) unless exception_code == "POL3003"

          # enque_message_delivery
          # [nil, "qeueued"]
        end

        def policy_error(explanation)
          if explanation
            I18n.t("policy_error", scope: "decidim.sms.telia.gateway.errors", message: explanation[0], code: explanation[1])
          else
            I18n.t("policy_error", scope: "decidim.sms.telia.gateway.errors", message: "", code: "")
          end
        end

        def log_policy_error(message, code)
          Rails.logger.error "Telia error -- Telia failed to deliver the code"
          Rails.logger.error "Telia Error: #{code}"
          Rails.logger.error message
        end

        def enque_message_delivery
          return if @queued

          RetryFailedDeliveryJob
            .set(wait: sms_retry_delay.seconds)
            .perform_later(
              remove_prefix(phone_number),
              code,
              organization: organization,
              queued: true
            )
        end

        def sms_retry_delay
          ::Decidim::Sms::Telia.sms_retry_delay
        end
      end
    end
  end
end
