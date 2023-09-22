# frozen_string_literal: true

require "spec_helper"

describe Decidim::Sms::Telia::Gateway do
  include_context "with Telia SMS token endpoint"
  include_context "with Telia Messaging endpoint"

  let(:organization) { create(:organization) }

  shared_examples "working messaging API" do
    let(:gateway) { described_class.new(phone_number, message, organization: organization) }
    let(:phone_number) { "+358401234567" }
    let(:message) { "Testing message" }

    describe "#deliver_code" do
      subject { gateway.deliver_code }

      it { is_expected.to be(true) }

      it "creates a new delivery" do
        expect { subject }.to change(Decidim::Sms::Telia::Delivery, :count).by(1)

        delivery = Decidim::Sms::Telia::Delivery.last
        expect(delivery.to).to eq(phone_number)
        expect(delivery.from).to eq(Rails.application.secrets.telia[:sender_address])
        expect(delivery.status).to eq("sent")
        expect(delivery.resource_url).to eq(resource_url)
        expect(delivery.callback_data).to match(/[a-zA-Z0-9]{32}/)
      end

      context "with incorrect credentials" do
        let(:auth_token_credentials) { %w(foo bar) }

        it "raises a TeliaAuthenticationError" do
          expect { subject }.to raise_error(Decidim::Sms::Telia::TeliaAuthenticationError)
        end
      end

      context "with invalid authorization token" do
        let(:authorization_token) { "foobar" }

        it "raises a TeliaServerError" do
          expect { subject }.to raise_error(Decidim::Sms::Telia::TeliaServerError)
        end
      end

      context "with policy errors" do
        {
          "POL3003" => :server_busy,
          "POL3101" => :invalid_to_number,
          "POL3006" => :destination_whitelist,
          "POL3007" => :destination_blacklist
        }.each do |code, error|
          context "when #{code}" do
            let(:messaging_api_policy_exception) { code }
            let(:gateway_error) { error }

            it "throws a TeliaPolicyError" do
              expect { subject }.to raise_error(Decidim::Sms::Telia::TeliaPolicyError)

              begin
                subject
              rescue Decidim::Sms::Telia::TeliaPolicyError => e
                expect(e.error_code).to be(gateway_error)
              end
            end
          end
        end

        context "when unknown" do
          let(:messaging_api_policy_exception) { "POL9999" }

          it "throws a TeliaPolicyError" do
            expect { subject }.to raise_error(Decidim::Sms::Telia::TeliaPolicyError)

            begin
              subject
            rescue Decidim::Sms::Telia::TeliaPolicyError => e
              expect(e.error_code).to be(:unknown)
            end
          end
        end
      end
    end
  end

  context "with the sandbox endpoint" do
    let(:api_mode) { "sandbox" }

    context "with default behavior" do
      it_behaves_like "working messaging API"
    end

    context "when the mode is unknown" do
      before do
        telia_secrets = Rails.application.secrets.telia
        allow(Rails.application.secrets).to receive(:telia).and_return(
          telia_secrets.merge(mode: "foobar")
        )
      end

      it_behaves_like "working messaging API"
    end
  end

  context "with the production endpoint" do
    let(:api_mode) { "production" }

    before do
      allow(Rails.env).to receive(:test?).and_return(false)
    end

    context "with default behavior" do
      it_behaves_like "working messaging API"
    end

    context "when set through the secrrets" do
      before do
        telia_secrets = Rails.application.secrets.telia
        allow(Rails.application.secrets).to receive(:telia).and_return(
          telia_secrets.merge(mode: api_mode)
        )
      end

      it_behaves_like "working messaging API"
    end
  end
end
