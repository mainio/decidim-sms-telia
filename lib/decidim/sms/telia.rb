# frozen_string_literal: true

require "decidim/sms/telia/engine"

module Decidim
  module Sms
    # This namespace holds the logic for Telia SMS integration.
    module Telia
      autoload :Gateway, "decidim/sms/telia/gateway"
      autoload :Http, "decidim/sms/telia/http"
      autoload :TokenManager, "decidim/sms/telia/token_manager"

      include ActiveSupport::Configurable

      # Default configuration wait interval before retry sending a queued sms that was
      # failed due to a busy server.
      config_accessor :sms_retry_delay do
        10
      end
    end
  end
end
