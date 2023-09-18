# frozen_string_literal: true

module Decidim
  module Sms
    module Telia
      class RetryFailedDeliveryJob < ApplicationJob
        queue_as :default

        def perform(*params, queued: false)
          Gateway.new(params, queued: queued).deliver_code
        end
      end
    end
  end
end
