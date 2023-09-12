# frozen_string_literal: true

module Decidim
  module Sms
    module Telia
      module CallbackDataGenerator
        def generate_data
          Digest::MD5.hexdigest(select_sample)
        end

        private

        def select_sample
          characters = ("0".."9").to_a + ("A".."Z").to_a
          characters.sample(10).join
        end
      end
    end
  end
end
