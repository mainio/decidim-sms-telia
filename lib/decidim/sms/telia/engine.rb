# frozen_string_literal: true

require "rails"
require "decidim/core"

module Decidim
  module Sms
    module Telia
      # This is the engine that runs on the public interface of sms-telia.
      class Engine < ::Rails::Engine
        isolate_namespace Decidim::Sms::Telia

        routes do
          post "deliveries/:id", to: "deliveries#update", as: :delivery
        end

        initializer "sms_telia.mount_routes" do
          Decidim::Core::Engine.routes do
            mount Decidim::Sms::Telia::Engine => "/sms/telia"
          end
        end

        initializer "sms_telia.configure_gateway", before: :load_config_initializers do
          Decidim.config.sms_gateway_service = "Decidim::Sms::Telia::Gateway"
        end

        initializer "sms_telia.webpacker.assets_path" do
          Decidim.register_assets_path File.expand_path("app/packs", root)
        end
      end
    end
  end
end
