# -*- encoding: utf-8 -*-
# stub: chunky_png 1.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "chunky_png".freeze
  s.version = "1.4.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "source_code_uri" => "https://github.com/wvanbergen/chunky_png", "wiki_uri" => "https://github.com/wvanbergen/chunky_png/wiki" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Willem van Bergen".freeze]
  s.date = "2020-12-28"
  s.description = "    This pure Ruby library can read and write PNG images without depending on an external\n    image library, like RMagick. It tries to be memory efficient and reasonably fast.\n\n    It supports reading and writing all PNG variants that are defined in the specification,\n    with one limitation: only 8-bit color depth is supported. It supports all transparency,\n    interlacing and filtering options the PNG specifications allows. It can also read and\n    write textual metadata from PNG files. Low-level read/write access to PNG chunks is\n    also possible.\n\n    This library supports simple drawing on the image canvas and simple operations like\n    alpha composition and cropping. Finally, it can import from and export to RMagick for\n    interoperability.\n\n    Also, have a look at OilyPNG at https://github.com/wvanbergen/oily_png. OilyPNG is a\n    drop in mixin module that implements some of the ChunkyPNG algorithms in C, which\n    provides a massive speed boost to encoding and decoding.\n".freeze
  s.email = ["willem@railsdoctors.com".freeze]
  s.extra_rdoc_files = ["README.md".freeze, "BENCHMARKING.rdoc".freeze, "CONTRIBUTING.rdoc".freeze, "CHANGELOG.rdoc".freeze]
  s.files = ["BENCHMARKING.rdoc".freeze, "CHANGELOG.rdoc".freeze, "CONTRIBUTING.rdoc".freeze, "README.md".freeze]
  s.homepage = "https://github.com/wvanbergen/chunky_png/wiki".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--title".freeze, "chunky_png".freeze, "--main".freeze, "README.rdoc".freeze, "--line-numbers".freeze, "--inline-source".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Pure ruby library for read/write, chunk-level access to PNG files".freeze

  s.installed_by_version = "4.0.3".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<standard>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.9".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3".freeze])
end
