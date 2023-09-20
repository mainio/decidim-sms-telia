# frozen_string_literal: true

shared_context "with telia gateway" do
  let(:token_uri) do
    double(
      host: "api.opaali.telia.fi/autho4api/v1/token",
      port: 8_080
    )
  end
  let(:revoke_uri) do
    double(
      host: "api.opaali.telia.fi/autho4api/v1/revoke",
      port: 8_080
    )
  end
  let(:credentials) { "DummyCredentials" }
  let(:token) { nil }
  let(:telia_credentials_uname) { "dummycredentialsuname" }
  let(:telia_credentials_pword) { "dummycredentialpword" }
  let(:telia_sender_address) { "dummysenderaddress" }
  let(:telia_sender_name) { "dummyname" }

  let(:twilio_sender) { "1234567890" }
  let(:phone_number) { "+3585478373617" }
  let(:sid) { "Dummy sms id" }
  let!(:code) { "1234567" }
  let!(:status) { "qeued" }
  let(:dummy_response) do
    %({
      "account_sid": "#{account_sid}",
      "status": "#{status}",
      "to": "#{phone_number}",
      "sid": "#{sid}",
      "from": "#{phone_number}",
      "api_version": "#{api_version}"
    })
  end

  before do
    allow(Decidim::HelsinkiSmsauth).to receive(:country_code).and_return({ country: "FI", code: "+358" })
    allow(Rails.application.secrets).to receive(:telia).and_return(
      {
        telia_credentials_uname: telia_credentials_uname,
        telia_credentials_pword: telia_credentials_pword,
        telia_sender_address: telia_sender_address,
        telia_sender_name: telia_sender_name
      }
    )
    stub_request(:any, token_uri)
      .to_return(body: dummy_response)
    allow(SecureRandom).to receive(:random_number).and_return(1_234_567)
  end
end
