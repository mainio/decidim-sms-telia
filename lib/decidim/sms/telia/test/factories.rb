# frozen_string_literal: true

module Decidim
  module Sms
    module Telia
      module Faker
        # Characters 0-9 (48..57), A-Z (65..90) and a-z (97..122)
        def self.callback_data
          [(48..57), (65..90), (97..122)].map { |r| r.map(&:chr) }.flatten.sample(32).join
        end
      end
    end
  end
end

FactoryBot.define do
  # Add engine factories here
  factory :telia_sms_delivery, class: "Decidim::Sms::Telia::Delivery" do
    from { Faker::PhoneNumber.cell_phone_in_e164 }
    to { Faker::PhoneNumber.cell_phone_in_e164 }
    status { "initiated" }
    resource_url { "https://api.opaali.telia.fi/production/messaging/v1/outbound/tel%3A%2B358000000000/requests/nnn" }
    callback_data { Decidim::Sms::Telia::Faker.callback_data }

    trait :sent do
      status { "sent" }
    end
  end
end
