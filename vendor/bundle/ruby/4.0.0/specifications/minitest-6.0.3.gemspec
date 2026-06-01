# -*- encoding: utf-8 -*-
# stub: minitest 6.0.3 ruby lib

Gem::Specification.new do |s|
  s.name = "minitest".freeze
  s.version = "6.0.3".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/minitest/minitest/issues", "changelog_uri" => "https://github.com/minitest/minitest/blob/master/History.rdoc", "documentation_uri" => "https://docs.seattlerb.org/minitest", "homepage_uri" => "https://minite.st/", "source_code_uri" => "https://github.com/minitest/minitest" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ryan Davis".freeze]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIDPjCCAiagAwIBAgIBCjANBgkqhkiG9w0BAQsFADBFMRMwEQYDVQQDDApyeWFu\nZC1ydWJ5MRkwFwYKCZImiZPyLGQBGRYJemVuc3BpZGVyMRMwEQYKCZImiZPyLGQB\nGRYDY29tMB4XDTI2MDEwNzAxMDkxNFoXDTI3MDEwNzAxMDkxNFowRTETMBEGA1UE\nAwwKcnlhbmQtcnVieTEZMBcGCgmSJomT8ixkARkWCXplbnNwaWRlcjETMBEGCgmS\nJomT8ixkARkWA2NvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALda\nb9DCgK+627gPJkB6XfjZ1itoOQvpqH1EXScSaba9/S2VF22VYQbXU1xQXL/WzCkx\ntaCPaLmfYIaFcHHCSY4hYDJijRQkLxPeB3xbOfzfLoBDbjvx5JxgJxUjmGa7xhcT\noOvjtt5P8+GSK9zLzxQP0gVLS/D0FmoE44XuDr3iQkVS2ujU5zZL84mMNqNB1znh\nGiadM9GHRaDiaxuX0cIUBj19T01mVE2iymf9I6bEsiayK/n6QujtyCbTWsAS9Rqt\nqhtV7HJxNKuPj/JFH0D2cswvzznE/a5FOYO68g+YCuFi5L8wZuuM8zzdwjrWHqSV\ngBEfoTEGr7Zii72cx+sCAwEAAaM5MDcwCQYDVR0TBAIwADALBgNVHQ8EBAMCBLAw\nHQYDVR0OBBYEFEfFe9md/r/tj/Wmwpy+MI8d9k/hMA0GCSqGSIb3DQEBCwUAA4IB\nAQA/X8/PKTTc/IkYQEUL6XWtfK8fAfbuLJzmLcz6f2ZWrtBvPsYvqRuwI1bWUtil\n2ibJEfIuSIHX6BsUTX18+hlaIussf6EWq/YkE7e2BKmgQE42vSOZMce0kCEAPbx0\nrQtqonfWTHQ8UbQ7GqCL3gDQ0QDD2B+HUlb4uaCZ2icxqa/eOtxMvHC2tj+h0xKY\nxL84ipM5kr0bHGf9/MRZJWcw51urueNycBXu1Xh+pEN8qBmYsFRR4SIODLClybAO\n6cbm2PyPQgKNiqE4H+IQrDVHd9bJs1XgLElk3qoaJBWXc/5fy0J1imYb25UqmiHG\nsnGe1hrppvBRdcyEzvhfIPjI\n-----END CERTIFICATE-----\n".freeze]
  s.date = "1980-01-02"
  s.description = "minitest provides a complete suite of testing facilities supporting\nTDD, BDD, and benchmarking.\n\n    \"I had a class with Jim Weirich on testing last week and we were\n     allowed to choose our testing frameworks. Kirk Haines and I were\n     paired up and we cracked open the code for a few test\n     frameworks...\n\n     I MUST say that minitest is *very* readable / understandable\n     compared to the 'other two' options we looked at. Nicely done and\n     thank you for helping us keep our mental sanity.\"\n\n    -- Wayne E. Seguin\n\nminitest/test is a small and incredibly fast unit testing framework.\nIt provides a rich set of assertions to make your tests clean and\nreadable.\n\nminitest/spec is a functionally complete spec engine. It hooks onto\nminitest/test and seamlessly bridges test assertions over to spec\nexpectations.\n\nminitest/benchmark is an awesome way to assert the performance of your\nalgorithms in a repeatable manner. Now you can assert that your newb\nco-worker doesn't replace your linear algorithm with an exponential\none!\n\nminitest/pride shows pride in testing and adds coloring to your test\noutput. I guess it is an example of how to write IO pipes too. :P\n\nminitest/test is meant to have a clean implementation for language\nimplementors that need a minimal set of methods to bootstrap a working\ntest suite. For example, there is no magic involved for test-case\ndiscovery.\n\n    \"Again, I can't praise enough the idea of a testing/specing\n     framework that I can actually read in full in one sitting!\"\n\n    -- Piotr Szotkowski\n\nComparing to rspec:\n\n    rspec is a testing DSL. minitest is ruby.\n\n    -- Adam Hawkins, \"Bow Before MiniTest\"\n\nminitest doesn't reinvent anything that ruby already provides, like:\nclasses, modules, inheritance, methods. This means you only have to\nlearn ruby to use minitest and all of your regular OO practices like\nextract-method refactorings still apply.\n\n== Features/Problems:\n\n* minitest/autorun - the easy and explicit way to run all your tests.\n* minitest/test - a very fast, simple, and clean test system.\n* minitest/spec - a very fast, simple, and clean spec system.\n* minitest/benchmark - an awesome way to assert your algorithm's performance.\n* minitest/pride - show your pride in testing!\n* minitest/test_task - a full-featured and clean rake task generator.\n* Incredibly small and fast runner, but no bells and whistles.\n* Written by squishy human beings. Software can never be perfect. We will all eventually die.".freeze
  s.email = ["ryand-ruby@zenspider.com".freeze]
  s.executables = ["minitest".freeze]
  s.extra_rdoc_files = ["History.rdoc".freeze, "Manifest.txt".freeze, "README.rdoc".freeze]
  s.files = ["History.rdoc".freeze, "Manifest.txt".freeze, "README.rdoc".freeze, "bin/minitest".freeze]
  s.homepage = "https://minite.st/".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--main".freeze, "README.rdoc".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.2".freeze)
  s.rubygems_version = "3.7.2".freeze
  s.summary = "minitest provides a complete suite of testing facilities supporting TDD, BDD, and benchmarking".freeze

  s.installed_by_version = "4.0.3".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<prism>.freeze, ["~> 1.5".freeze])
  s.add_runtime_dependency(%q<drb>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<rdoc>.freeze, [">= 6.0".freeze, "< 8".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.21".freeze])
  s.add_development_dependency(%q<hoe>.freeze, ["~> 4.6".freeze])
end
