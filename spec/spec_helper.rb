# frozen_string_literal: true

require "decidim/dev"

ENV["ENGINE_ROOT"] = File.dirname(__dir__)
ENV["NODE_ENV"] ||= "test"

Decidim::Dev.dummy_app_path = File.expand_path(File.join(__dir__, "decidim_dummy_app"))

require "decidim/dev/test/base_spec_helper"

RSpec.configure do |config|
  config.before do
    Rails.application.secrets.telia = {
      sender_address: "+358000000000",
      sender_name: "Mainio",
      username: "uname",
      password: "pword"
    }
  end
end
