# frozen_string_literal: true

module Decidim
  module Sms
    module Telia
      class Geteway
        def initialize(authorization)
          @authorization = authorization
        end

        def send_message!(options)
          # Construct the URL
          uri = URI.parse("https://api.opaali.telia.fi/production/messaging/v1/outbound/#{@sender_address}/requests")

          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true

          request = ::Net::HTTP::Post.new(uri.path, "Content-Type" => "application/json")

          request["Authorization"] = "Bearer #{@authorization}"

          request.body = {
            outboundMessageRequest: {
              address: options[:address],
              senderAddress: @sender_address,
              outboundSMSBinaryMessage: {
                message: options[:message]
              },
              senderName: "Telia",
              receiptRequest: {
                notifyURL: options[:notify_url],
                notificationFormat: "JSON",
                callbackData: options[:callback_data]
              }
            }
          }.to_json

          response = http.request(request)

          if response.code.to_i == 200
            puts "Request successful!"
          else
            puts "Request failed with code: #{response.code}"
          end
          puts "Response body: #{response.body}"
        end
      end
    end
  end
end
