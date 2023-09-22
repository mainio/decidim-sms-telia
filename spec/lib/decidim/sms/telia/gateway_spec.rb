# frozen_string_literal: true

require "spec_helper"

describe Decidim::Sms::Telia::Gateway do
  include_context "with Telia SMS token endpoint"

  let(:organization) { create(:organization) }
  let(:api_response_headers) do
    {
      "Content-Type" => "application/json;charset=utf-8",
      "Transfer-Encoding" => "chunked",
      "Connection" => "keep-alive",
      "Accept" => "application/json;charset=utf-8",
      "Server" => "Operator Service Platform"
    }
  end
  let(:sender_address) { "tel:#{Rails.application.secrets.telia[:sender_address]}" }
  let(:resource_url) { "https://api.opaali.telia.fi/production/messaging/v1/outbound/#{CGI.escape(sender_address)}/requests/nnn" }

  before do
    stub_request(
      :post,
      "https://api.opaali.telia.fi/#{api_mode}/messaging/v1/outbound/#{CGI.escape(sender_address)}/requests"
    ).to_return do
      body = {
        resourceReference: {
          resourceURL: resource_url
        }
      }.to_json

      {
        body: body,
        headers: api_response_headers.merge(
          "Date" => Time.now.httpdate,
          "Location" => resource_url
        )
      }
    end
  end

  shared_examples "working messaging API" do
    let(:gateway) { described_class.new(phone_number, message, organization: organization) }
    let(:phone_number) { "+358401234567" }
    let(:message) { "Testing message" }

    describe "#deliver_code" do
      subject { gateway.deliver_code }

      it { is_expected.to be(true) }

      it "creates a new delivery" do
        expect { gateway.deliver_code }.to change(Decidim::Sms::Telia::Delivery, :count).by(1)

        delivery = Decidim::Sms::Telia::Delivery.last
        expect(delivery.to).to eq(phone_number)
        expect(delivery.from).to eq(Rails.application.secrets.telia[:sender_address])
        expect(delivery.status).to eq("sent")
        expect(delivery.resource_url).to eq(resource_url)
        expect(delivery.callback_data).to match(/[a-zA-Z0-9]{32}/)
      end
    end
  end

  context "with the sandbox endpoint" do
    let(:api_mode) { "sandbox" }

    it_behaves_like "working messaging API"
  end

  context "with the production endpoint" do
    let(:api_mode) { "production" }

    before do
      allow(Rails.env).to receive(:test?).and_return(false)
    end

    it_behaves_like "working messaging API"
  end
end
