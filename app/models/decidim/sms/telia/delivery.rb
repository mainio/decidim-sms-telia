# frozen_string_literal: true

module Decidim
  module Sms
    module Telia
      # The data store for a Delivery status of messages being sent to the users
      class Delivery < Telia::ApplicationRecord
        before_create :generate_callback_code

        def generate_callback_code
          loop do
            self.callback_code = generate_digest
            if ::Decidim::Sms::Telia::Delivery.find_by(callback_code: callback_code).blank?
              save!
            end
          end
        end

        private

        def generate_digest
          characters = ("0".."9").to_a + ("A".."Z").to_a + ("a".."a").to_a
          characters.sample(32).join
        end
      end
    end
  end
end
