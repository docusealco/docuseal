# frozen_string_literal: true

require_relative "version_gem/version"
require_relative "version_gem/basic"
require_relative "version_gem/epoch"

# Namespace of this library
module VersionGem
end

VersionGem::Version.class_eval do
  extend VersionGem::Basic
end
