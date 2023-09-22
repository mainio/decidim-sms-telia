# frozen_string_literal: true

shared_context "with Telia SMS token endpoint" do
  let(:auth_endpoint_headers) do
    {
      "Content-Type" => "application/json;charset=utf-8",
      "Connection" => "keep-alive",
      "Accept" => "application/json;charset=utf-8",
      "Server" => "Operator Service Platform"
    }
  end
  let(:auth_token_expires_in) { 540 }
  let(:auth_token_generation_time) { Time.zone.now }
  let(:auth_token_expiration_time) { token_generation_time + token_expires_in.seconds }
  let(:auth_token_credentials) do
    [
      Rails.application.secrets.telia[:username],
      Rails.application.secrets.telia[:password]
    ]
  end

  before do
    # Token endpoint
    stub_request(
      :post,
      "https://api.opaali.telia.fi/autho4api/v1/token"
    ).to_return do |request|
      if request.headers["Authorization"] == "Basic #{Base64.encode64(auth_token_credentials.join(":")).strip}"
        auth_token_generation_time
        body = {
          access_token: "abcdef1234567890",
          token_type: "bearer",
          expires_in: auth_token_expires_in
        }.to_json

        {
          body: body,
          headers: auth_endpoint_headers.merge(
            "Date" => Time.now.httpdate,
            "Cache-Control" => "no-store",
            "Pragma" => "no-cache",
            "Content-Length" => body.length
          )
        }
      else
        {
          status: 401,
          body: "",
          headers: auth_endpoint_headers.merge(
            "Date" => Time.now.httpdate,
            "Cache-Control" => "no-store",
            "Pragma" => "no-cache",
            "Content-Length" => 0
          )
        }
      end
    end

    # Revoke endpoint
    stub_request(
      :post,
      "https://api.opaali.telia.fi/autho4api/v1/revoke"
    ).to_return do
      {
        body: "",
        headers: auth_endpoint_headers.merge("Date" => Time.now.httpdate, "Content-Length" => 0)
      }
    end
  end
end
