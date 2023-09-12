# frozen_string_literal: true

require "decidim/sms/telia/engine"

module Decidim
  module Sms
    # This namespace holds the logic for Telia SMS integration.
    module Telia
      autoload :Gateway, "decidim/sms/telia/gateway"
    end
  end
end
