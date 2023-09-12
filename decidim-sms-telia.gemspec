# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "decidim/sms/telia/version"

Gem::Specification.new do |s|
  s.version = Decidim::Sms::Telia.version
  s.authors = ["Sina Eftekhar"]
  s.email = ["sina.eftekhar@mainiotech.fi"]
  s.license = "AGPL-3.0"
  s.homepage = "https://github.com/mainio/decidim-module-ptp"
  s.required_ruby_version = ">= 3.0"

  s.name = "decidim-sms-telia"
  s.summary = "A decidim sms-telia module"
  s.description = "Telia SMS provider integration."

  s.files = Dir["{app,config,lib}/**/*", "LICENSE-AGPLv3.txt", "Rakefile", "README.md"]

  s.add_dependency "decidim-core", Decidim::Sms::Telia.decidim_version
  s.metadata["rubygems_mfa_required"] = "true"
end
