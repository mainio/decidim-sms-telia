# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION

# Inside the development app, the relative require has to be one level up, as
# the Gemfile is copied to the development_app folder (almost) as is.
base_path = ""
base_path = "../" if File.basename(__dir__) == "development_app"
require_relative "#{base_path}lib/decidim/sms/telia/version"

DECIDIM_VERSION = Decidim::Sms::Telia.decidim_version

gem "decidim", DECIDIM_VERSION
gem "decidim-sms-telia", path: "."

group :development, :test do
  gem "decidim-dev", DECIDIM_VERSION
  gem "rubocop-faker"
end
