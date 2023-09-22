# frozen_string_literal: true

namespace :decidim do
  namespace :sms_telia do
    desc "Test sending of the SMS"
    task :test, [:organization, :number] => :environment do |_t, args|
      unless Decidim.config.sms_gateway_service
        puts "The gateway has not been configured. Please review the initializer code."
        next
      end

      organization = Decidim::Organization.find_by(id: args[:organization])
      unless organization
        puts "Please provide an organization ID as the first argument."
        next
      end

      number = args[:number]
      if number.blank?
        puts "Please provide a phone number to send the test message to as the second argument."
        next
      end

      message = "Test message from Decidim."
      gateway = Decidim.config.sms_gateway_service.constantize.new(number, message, organization: organization, debug: true)

      if gateway.deliver_code
        puts "The test message has been successfully sent to: #{number}"
      else
        puts "Failed to deliver message to '#{number}'. Please double check the provided phone number."
      end
    end
  end
end
