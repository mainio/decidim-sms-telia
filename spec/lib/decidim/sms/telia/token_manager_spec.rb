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

    context "with caching" do
      let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

      before do
        allow(Rails).to receive(:cache).and_return(memory_store)
      end

      it_behaves_like "valid token"

      context "when the token has been cached" do
        before { manager.fetch }

        it "stores the cached token" do
          expect(Rails.cache.read("decidim/sms/telia/token")).to be_a(Decidim::Sms::Telia::Token)
        end

        it "does not re-request the token" do
          expect(manager).not_to receive(:request)
          expect(subject).to be_a(Decidim::Sms::Telia::Token)
        end

        context "and the cached token has expired" do
          before do
            token = manager.fetch
            token.instance_variable_set(:@expires_at, 1.hour.ago)
            Rails.cache.write("decidim/sms/telia/token", token)
          end

          it "requests a new token" do
            expect(manager).to receive(:request).and_call_original
            expect(subject.expired?).to be(false)
          end
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

    context "when the token has been cached through the rails cache" do
      let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }
      let(:token) { manager.request }

      before do
        allow(Rails).to receive(:cache).and_return(memory_store)
        Rails.cache.write("decidim/sms/telia/token", token)
      end

      it "revokes the cached token" do
        expect(Rails.cache).to receive(:read).and_call_original
        expect(subject).to be(true)
      end
    end
  end
end
