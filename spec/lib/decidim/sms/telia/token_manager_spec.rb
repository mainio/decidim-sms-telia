# frozen_string_literal: true

require "spec_helper"

describe Decidim::Sms::Telia::TokenManager do
  include_context "with Telia SMS token endpoint"

  let(:manager) { described_class.new }

  shared_examples "valid token" do
    it { is_expected.to be_a(Decidim::Sms::Telia::Token) }

    it "has the correct token" do
      expect(subject.to_s).to eq("abcdef1234567890")
    end

    context "with incorrect credentials" do
      let(:auth_token_credentials) { %w(foo bar) }

      it { is_expected.to be_nil }
    end
  end

  describe "#request" do
    subject { manager.request }

    it_behaves_like "valid token"
  end

  describe "#fetch" do
    subject { manager.fetch }

    it_behaves_like "valid token"

    context "when the token has been already fetched" do
      let!(:token) { create(:telia_sms_token) }

      it "has the correct token" do
        expect(subject.to_s).to eq("abcdef1234567890")

        expect(Decidim::Sms::Telia::Token.count).to eq(1)
      end

      it "does not re-request the token" do
        expect(manager).not_to receive(:request)
        expect(subject).to be_a(Decidim::Sms::Telia::Token)
        expect(Decidim::Sms::Telia::Token.count).to eq(1)
      end

      context "and the existing token has expired" do
        before do
          token.update!(expires_at: 1.hour.ago)
        end

        it "requests a new token" do
          expect(manager).to receive(:request).and_call_original
          expect(subject.expired?).to be(false)
          expect(Decidim::Sms::Telia::Token.count).to eq(1)
        end

        context "with incorrect credentials" do
          let(:auth_token_credentials) { %w(foo bar) }

          it { is_expected.to be_nil }
        end
      end
    end
  end

  describe "#revoke" do
    subject { manager.revoke(token) }

    let(:token) do
      Decidim::Sms::Telia::Token.from(
        "access_token" => "abcdef1234567890",
        "issued_at" => token_issued_at,
        "expires_in" => 9.minutes
      )
    end
    let(:token_issued_at) { Time.zone.now }

    context "when the token has been issued" do
      it { is_expected.to be(true) }

      context "and the token has expired" do
        let(:token_issued_at) { 10.minutes.ago }

        # The token revokation request should succeed regardless of the token
        # validity.
        it { is_expected.to be(true) }
      end

      context "and the credentials are invalid" do
        before do
          # Make sure the correct credentials are stored for the API.
          auth_token_credentials

          allow(Rails.application.secrets).to receive(:telia).and_return(
            username: "foo",
            password: "bar"
          )
        end

        it { is_expected.to be(false) }
      end
    end
  end

  describe "#revoke_cached_token" do
    subject { manager.revoke_cached_token }

    context "when the token has not been cached" do
      it { is_expected.to be(false) }
    end

    context "when the token has been locally cached" do
      let(:token) { manager.fetch }

      it "revokes the token" do
        expect(manager).to receive(:revoke).with(token).and_call_original
        expect(subject).to be(true)
      end
    end
  end
end
