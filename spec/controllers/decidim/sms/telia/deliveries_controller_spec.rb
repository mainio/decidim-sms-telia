# frozen_string_literal: true

require "spec_helper"

describe Decidim::Sms::Telia::DeliveriesController, type: :controller do
  routes { Decidim::Sms::Telia::Engine.routes }

  let!(:organization) { create(:organization) }
  let!(:delivery) { create(:telia_sms_delivery, :sent) }

  before do
    request.env["decidim.current_organization"] = organization

    # Documentation shows that these are the headers although the request body
    # would be XML.
    request.headers["Accept"] = "application/json"
    request.headers["Content-Type"] = "application/json"
  end

  describe "POST update" do
    let(:callback_data) { delivery.callback_data }
    let(:notification_status) { "DeliveredToTerminal" }

    shared_examples "working delivery endpoint" do
      it "responds successfully and updates the status" do
        post :update, params: { id: delivery.id }, body: notification_body
        expect(response).to have_http_status(:no_content)

        delivery.reload
        expect(delivery.status).to eq("delivered_to_terminal")
      end

      context "with delivery status set to DeliveryImpossible" do
        let(:notification_status) { "DeliveryImpossible" }

        it "responds successfully and updates the status" do
          post :update, params: { id: delivery.id }, body: notification_body
          expect(response).to have_http_status(:no_content)

          delivery.reload
          expect(delivery.status).to eq("delivery_impossible")
        end
      end

      context "when the callbackData does not match the one of the delivery" do
        let(:callback_data) { "foobar" }

        it "responds with a forbidden (403) status" do
          post :update, params: { id: delivery.id }, body: notification_body
          expect(response).to have_http_status(:forbidden)
        end
      end

      context "when the ID of the request does not exist" do
        it "raises a ActionController::RoutingError" do
          expect { post :update, params: { id: delivery.id + 10 }, body: notification_body }.to raise_error(ActionController::RoutingError)
        end
      end
    end

    context "when valid delivery data as XML" do
      let(:notification_body) do
        <<~XML.squish
          <?xml version="1.0" encoding="UTF-8"?>
          <msg:deliveryInfoNotification xmlns:msg="urn:oma:xml:rest:netapi:messaging:1">
            <callbackData>#{callback_data}</callbackData>
            <deliveryInfo>
              <address>tel:#{delivery.to}</address>
              <deliveryStatus>#{notification_status}</deliveryStatus>
            </deliveryInfo>
            <link rel="OutboundMessageRequest" href="https://api.opaali.telia.fi/production/messaging/v1/outbound/tel%3A%2B358000000000/requests/12abcdef-abcd-abcd-abcd-123456abcdef"/>
          </msg:deliveryInfoNotification>
        XML
      end

      it_behaves_like "working delivery endpoint"

      context "when the request body does not have the correct node" do
        let(:notification_body) do
          <<~XML.squish
            <?xml version="1.0" encoding="UTF-8"?>
            <msg:deliveryInfoNotification xmlns:msg="urn:oma:xml:rest:netapi:messaging:1">
              <fooInfo>
                <bar>Baz</bar>
              </fooInfo>
            </msg:deliveryInfoNotification>
          XML
        end

        it "raises a ActionController::RoutingError" do
          expect { post :update, params: { id: delivery.id }, body: notification_body }.to raise_error(ActionController::RoutingError)
        end
      end
    end

    context "when valid delivery data as JSON" do
      let(:notification_body) do
        {
          "callbackData" => callback_data,
          "deliveryInfo" => {
            "address" => "tel:#{delivery.to}",
            "deliveryStatus" => notification_status
          },
          "link" => {
            "rel" => "OutboundMessageRequest",
            "href" => "https://api.opaali.telia.fi/production/messaging/v1/outbound/tel%3A%2B358000000000/requests/12abcdef-abcd-abcd-abcd-123456abcdef"
          }
        }.to_json
      end

      it_behaves_like "working delivery endpoint"

      context "when the request body does not have the correct node" do
        let(:notification_body) do
          { "fooInfo" => { "bar" => "Baz" } }.to_json
        end

        it "raises a ActionController::RoutingError" do
          expect { post :update, params: { id: delivery.id }, body: notification_body }.to raise_error(ActionController::RoutingError)
        end
      end
    end
  end
end
