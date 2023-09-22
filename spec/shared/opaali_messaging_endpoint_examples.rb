# frozen_string_literal: true

shared_context "with Telia Messaging endpoint" do
  let(:sender_address) { "tel:#{Rails.application.secrets.telia[:sender_address]}" }
  let(:authorization_token) { "abcdef1234567890" }
  let(:resource_url) { "https://api.opaali.telia.fi/production/messaging/v1/outbound/#{CGI.escape(sender_address)}/requests/12abcdef-abcd-abcd-abcd-123456abcdef" }

  let(:messaging_api_response_headers) do
    {
      "Content-Type" => "application/json;charset=utf-8",
      "Transfer-Encoding" => "chunked",
      "Connection" => "keep-alive",
      "Accept" => "application/json;charset=utf-8",
      "Server" => "Operator Service Platform"
    }
  end
  let(:messaging_api_policy_exception) { nil }

  before do
    stub_request(
      :post,
      "https://api.opaali.telia.fi/#{api_mode}/messaging/v1/outbound/#{CGI.escape(sender_address)}/requests"
    ).to_return do |request|
      if request.headers["Authorization"] == "Bearer #{authorization_token}"
        headers = messaging_api_response_headers.merge("Date" => Time.now.httpdate)

        if messaging_api_policy_exception
          body = {
            requestError: {
              policyException: {
                messageId: messaging_api_policy_exception,
                text: "The following policy error occurred: %1. Error code is %2.",
                variables: [
                  "Error message",
                  "POL-NNN"
                ]
              }
            }
          }

          {
            status: 403,
            body: body.to_json,
            headers: headers
          }
        else
          body = {
            resourceReference: {
              resourceURL: resource_url
            }
          }
          {
            body: body.to_json,
            headers: headers.merge("Location" => resource_url)
          }
        end
      else
        {
          status: 403,
          body: "",
          headers: messaging_api_response_headers.merge("Date" => Time.now.httpdate)
        }
      end
    end
  end
end
