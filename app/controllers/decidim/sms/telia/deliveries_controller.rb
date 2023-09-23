# frozen_string_literal: true

module Decidim
  module Sms
    module Telia
      class DeliveriesController < Decidim::Sms::Telia::ApplicationController
        # Prevent any before action calling the `params` method which could
        # potentially cause the Rails automagic to try to parse the JSON params
        # from the XML body (because the headers of the request are potentially
        # messed up).
        skip_before_action :verify_authenticity_token, :store_machine_translations_toggle
        skip_around_action :switch_locale, :use_organization_time_zone

        def update
          raise ActionController::RoutingError, "Not Found" unless delivery
          raise ActionController::RoutingError, "Not Found" unless delivery_info
          return render body: nil, status: :forbidden, content_type: "application/json" if delivery.callback_data != message["callbackData"]

          delivery.update!(status: delivery_info["deliveryStatus"].underscore) if delivery_info["deliveryStatus"].present?

          render body: nil, status: :no_content, content_type: "application/json"
        end

        private

        def delivery
          match = request.path.match(%r{^/deliveries/([0-9]+)})
          return unless match

          @delivery ||= Delivery.find_by(id: match[1])
        end

        def delivery_info
          message.try(:[], "deliveryInfo")
        end

        def message
          @message ||= begin
            msg = Nokogiri::XML.parse(request.body)
            if msg.at("//deliveryInfo")
              {
                "callbackData" => msg.at("//callbackData")&.text,
                "deliveryInfo" => (
                  %w(address deliveryStatus).index_with do |key|
                    msg.at("//deliveryInfo/#{key}")&.text
                  end
                )
              }
            else
              # Try parsing JSON if the XML does not contain the correct node
              JSON.parse(request.body.read)
            end
          rescue JSON::ParserError
            nil
          end
        end
      end
    end
  end
end
