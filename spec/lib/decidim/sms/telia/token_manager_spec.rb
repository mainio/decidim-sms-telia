# frozen_string_literal: true

require "spec_helper"

describe Decidim::Sms::Telia::TokenManager do
  include_context "with Telia SMS token endpoint"

  let(:manager) { described_class.new }

  describe "#generate_token" do
    subject { manager.generate_token }

    it { is_expected.to eq("abcdef1234567890") }

    context "with incorrect credentials" do
      let(:auth_token_credentials) { %w(foo bar) }

      it { is_expected.to be_nil }
    end
  end

  describe "#revoke_token" do
    subject { manager.revoke_token }

    context "when the token has not been issued" do
      it { is_expected.to be_nil }
    end

    context "when the token has been issued" do
      before { manager.generate_token }

      it { is_expected.to be(true) }

      context "and the credentials are invalid" do
        before do
          allow(Rails.application.secrets).to receive(:telia).and_return(
            username: "foo",
            password: "bar"
          )
        end

        it { is_expected.to be(false) }
      end
    end
  end
end
