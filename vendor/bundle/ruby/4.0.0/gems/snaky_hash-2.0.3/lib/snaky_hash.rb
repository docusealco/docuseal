# frozen_string_literal: true

# third party gems
require "hashie"
require "version_gem"

require_relative "snaky_hash/version"
require_relative "snaky_hash/extensions"
require_relative "snaky_hash/serializer"
require_relative "snaky_hash/snake"
require_relative "snaky_hash/string_keyed"
require_relative "snaky_hash/symbol_keyed"

# SnakyHash provides hash-like objects with automatic key conversion capabilities
#
# @example Using StringKeyed hash
#   hash = SnakyHash::StringKeyed.new
#   hash["camelCase"] = "value"
#   hash["camel_case"] # => "value"
#
# @example Using SymbolKeyed hash
#   hash = SnakyHash::SymbolKeyed.new
#   hash["camelCase"] = "value"
#   hash[:camel_case] # => "value"
#
# @see SnakyHash::StringKeyed
# @see SnakyHash::SymbolKeyed
# @see SnakyHash::Snake
module SnakyHash
  # Base error class for all SnakyHash errors
  #
  # @api public
  class Error < StandardError
  end
end

# Enable version introspection via VersionGem
#
# @api private
SnakyHash::Version.class_eval do
  extend VersionGem::Basic
end
