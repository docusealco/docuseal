# -*- encoding: utf-8 -*-
# stub: oauth2 2.0.18 ruby lib

Gem::Specification.new do |s|
  s.name = "oauth2".freeze
  s.version = "2.0.18".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/ruby-oauth/oauth2/issues", "changelog_uri" => "https://github.com/ruby-oauth/oauth2/blob/v2.0.18/CHANGELOG.md", "discord_uri" => "https://discord.gg/3qme4XHNKN", "documentation_uri" => "https://www.rubydoc.info/gems/oauth2/2.0.18", "funding_uri" => "https://github.com/sponsors/pboling", "homepage_uri" => "https://oauth2.galtzo.com/", "mailing_list_uri" => "https://groups.google.com/g/oauth-ruby", "news_uri" => "https://www.railsbling.com/tags/oauth2", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/ruby-oauth/oauth2/tree/v2.0.18", "wiki_uri" => "https://gitlab.com/ruby-oauth/oauth2/-/wiki" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Peter Boling".freeze, "Erik Michaels-Ober".freeze, "Michael Bleigh".freeze]
  s.bindir = "exe".freeze
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIEgDCCAuigAwIBAgIBATANBgkqhkiG9w0BAQsFADBDMRUwEwYDVQQDDAxwZXRl\nci5ib2xpbmcxFTATBgoJkiaJk/IsZAEZFgVnbWFpbDETMBEGCgmSJomT8ixkARkW\nA2NvbTAeFw0yNTA1MDQxNTMzMDlaFw00NTA0MjkxNTMzMDlaMEMxFTATBgNVBAMM\nDHBldGVyLmJvbGluZzEVMBMGCgmSJomT8ixkARkWBWdtYWlsMRMwEQYKCZImiZPy\nLGQBGRYDY29tMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAruUoo0WA\nuoNuq6puKWYeRYiZekz/nsDeK5x/0IEirzcCEvaHr3Bmz7rjo1I6On3gGKmiZs61\nLRmQ3oxy77ydmkGTXBjruJB+pQEn7UfLSgQ0xa1/X3kdBZt6RmabFlBxnHkoaGY5\nmZuZ5+Z7walmv6sFD9ajhzj+oIgwWfnEHkXYTR8I6VLN7MRRKGMPoZ/yvOmxb2DN\ncoEEHWKO9CvgYpW7asIihl/9GMpKiRkcYPm9dGQzZc6uTwom1COfW0+ZOFrDVBuV\nFMQRPswZcY4Wlq0uEBLPU7hxnCL9nKK6Y9IhdDcz1mY6HZ91WImNslOSI0S8hRpj\nyGOWxQIhBT3fqCBlRIqFQBudrnD9jSNpSGsFvbEijd5ns7Z9ZMehXkXDycpGAUj1\nto/5cuTWWw1JqUWrKJYoifnVhtE1o1DZ+LkPtWxHtz5kjDG/zR3MG0Ula0UOavlD\nqbnbcXPBnwXtTFeZ3C+yrWpE4pGnl3yGkZj9SMTlo9qnTMiPmuWKQDatAgMBAAGj\nfzB9MAkGA1UdEwQCMAAwCwYDVR0PBAQDAgSwMB0GA1UdDgQWBBQE8uWvNbPVNRXZ\nHlgPbc2PCzC4bjAhBgNVHREEGjAYgRZwZXRlci5ib2xpbmdAZ21haWwuY29tMCEG\nA1UdEgQaMBiBFnBldGVyLmJvbGluZ0BnbWFpbC5jb20wDQYJKoZIhvcNAQELBQAD\nggGBAJbnUwfJQFPkBgH9cL7hoBfRtmWiCvdqdjeTmi04u8zVNCUox0A4gT982DE9\nwmuN12LpdajxZONqbXuzZvc+nb0StFwmFYZG6iDwaf4BPywm2e/Vmq0YG45vZXGR\nL8yMDSK1cQXjmA+ZBKOHKWavxP6Vp7lWvjAhz8RFwqF9GuNIdhv9NpnCAWcMZtpm\nGUPyIWw/Cw/2wZp74QzZj6Npx+LdXoLTF1HMSJXZ7/pkxLCsB8m4EFVdb/IrW/0k\nkNSfjtAfBHO8nLGuqQZVH9IBD1i9K6aSs7pT6TW8itXUIlkIUI2tg5YzW6OFfPzq\nQekSkX3lZfY+HTSp/o+YvKkqWLUV7PQ7xh1ZYDtocpaHwgxe/j3bBqHE+CUPH2vA\n0V/FwdTRWcwsjVoOJTrYcff8pBZ8r2MvtAc54xfnnhGFzeRHfcltobgFxkAXdE6p\nDVjBtqT23eugOqQ73umLcYDZkc36vnqGxUBSsXrzY9pzV5gGr2I8YUxMqf6ATrZt\nL9nRqA==\n-----END CERTIFICATE-----\n".freeze]
  s.date = "1980-01-02"
  s.description = "\u{1F510} A Ruby wrapper for the OAuth 2.0 Authorization Framework, including the OAuth 2.1 draft spec, and OpenID Connect (OIDC)".freeze
  s.email = ["floss@galtzo.com".freeze, "oauth-ruby@googlegroups.com".freeze]
  s.extra_rdoc_files = ["CHANGELOG.md".freeze, "CITATION.cff".freeze, "CODE_OF_CONDUCT.md".freeze, "CONTRIBUTING.md".freeze, "FUNDING.md".freeze, "IRP.md".freeze, "LICENSE.txt".freeze, "OIDC.md".freeze, "README.md".freeze, "REEK".freeze, "RUBOCOP.md".freeze, "SECURITY.md".freeze, "THREAT_MODEL.md".freeze]
  s.files = ["CHANGELOG.md".freeze, "CITATION.cff".freeze, "CODE_OF_CONDUCT.md".freeze, "CONTRIBUTING.md".freeze, "FUNDING.md".freeze, "IRP.md".freeze, "LICENSE.txt".freeze, "OIDC.md".freeze, "README.md".freeze, "REEK".freeze, "RUBOCOP.md".freeze, "SECURITY.md".freeze, "THREAT_MODEL.md".freeze]
  s.homepage = "https://github.com/ruby-oauth/oauth2".freeze
  s.licenses = ["MIT".freeze]
  s.post_install_message = "\n---+++--- oauth2 v2.0.18 ---+++---\n\n(minor) \u26A0\uFE0F BREAKING CHANGES \u26A0\uFE0F when upgrading from < v2\n\u2022 Summary of breaking changes: https://gitlab.com/ruby-oauth/oauth2#what-is-new-for-v20\n\u2022 Changes in this patch: https://gitlab.com/ruby-oauth/oauth2/-/blob/v2.0.18/CHANGELOG.md#2015-2025-09-08\n\nNews:\n1. New documentation website, including for OAuth 2.1 and OIDC: https://oauth2.galtzo.com\n2. New official Discord for discussion and support: https://discord.gg/3qme4XHNKN\n3. New org name \"ruby-oauth\" on Open Source Collective, GitHub, GitLab, Codeberg (update git remotes!)\n4. Non-commercial support for the 2.x series will end by April, 2026. Please make a plan to upgrade to the next version prior to that date.\nSupport will be dropped for Ruby 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 3.0, 3.1 and any other Ruby versions which will also have reached EOL by then.\n5. Gem releases are cryptographically signed with a 20-year cert; SHA-256 & SHA-512 checksums by stone_checksums.\n6. Please consider supporting this project:\n   \u2022 https://opencollective.com/ruby-oauth (new!)\n   \u2022 https://liberapay.com/pboling\n   \u2022 https://github.com/sponsors/pboling\n   \u2022 https://www.paypal.com/paypalme/peterboling\n   \u2022 https://ko-fi.com/pboling\n   \u2022 https://www.buymeacoffee.com/pboling\n   \u2022 https://tidelift.com/funding/github/rubygems/oauth\n   \u2022 Hire me - I can build anything\n   \u2022 Report issues, and star the project\nThanks, @pboling / @galtzo\n".freeze
  s.rdoc_options = ["--title".freeze, "oauth2 - \u{1F510} OAuth 2.0, 2.1 & OIDC Core Ruby implementation".freeze, "--main".freeze, "README.md".freeze, "--exclude".freeze, "^sig/".freeze, "--line-numbers".freeze, "--inline-source".freeze, "--quiet".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.2.0".freeze)
  s.rubygems_version = "3.7.2".freeze
  s.summary = "\u{1F510} OAuth 2.0, 2.1 & OIDC Core Ruby implementation".freeze

  s.installed_by_version = "4.0.3".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<faraday>.freeze, [">= 0.17.3".freeze, "< 4.0".freeze])
  s.add_runtime_dependency(%q<jwt>.freeze, [">= 1.0".freeze, "< 4.0".freeze])
  s.add_runtime_dependency(%q<logger>.freeze, ["~> 1.2".freeze])
  s.add_runtime_dependency(%q<multi_xml>.freeze, ["~> 0.5".freeze])
  s.add_runtime_dependency(%q<rack>.freeze, [">= 1.2".freeze, "< 4".freeze])
  s.add_runtime_dependency(%q<snaky_hash>.freeze, ["~> 2.0".freeze, ">= 2.0.3".freeze])
  s.add_runtime_dependency(%q<version_gem>.freeze, ["~> 1.1".freeze, ">= 1.1.9".freeze])
  s.add_development_dependency(%q<addressable>.freeze, ["~> 2.8".freeze, ">= 2.8.7".freeze])
  s.add_development_dependency(%q<nkf>.freeze, ["~> 0.2".freeze])
  s.add_development_dependency(%q<rexml>.freeze, ["~> 3.2".freeze, ">= 3.2.5".freeze])
  s.add_development_dependency(%q<kettle-dev>.freeze, ["~> 1.1".freeze])
  s.add_development_dependency(%q<bundler-audit>.freeze, ["~> 0.9.2".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0".freeze])
  s.add_development_dependency(%q<require_bench>.freeze, ["~> 1.0".freeze, ">= 1.0.4".freeze])
  s.add_development_dependency(%q<appraisal2>.freeze, ["~> 3.0".freeze])
  s.add_development_dependency(%q<kettle-test>.freeze, ["~> 1.0".freeze, ">= 1.0.6".freeze])
  s.add_development_dependency(%q<ruby-progressbar>.freeze, ["~> 1.13".freeze])
  s.add_development_dependency(%q<stone_checksums>.freeze, ["~> 1.0".freeze, ">= 1.0.2".freeze])
  s.add_development_dependency(%q<gitmoji-regex>.freeze, ["~> 1.0".freeze, ">= 1.0.3".freeze])
  s.add_development_dependency(%q<backports>.freeze, ["~> 3.25".freeze, ">= 3.25.1".freeze])
end
