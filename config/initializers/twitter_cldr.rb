# frozen_string_literal: true

require 'twitter_cldr/shared/bidi'
require 'twitter_cldr/shared/code_point'
require 'twitter_cldr/resources/loader'

module TwitterCldr
  RESOURCES_DIR = File.join(Gem::Specification.find_by_name('twitter_cldr').gem_dir, 'resources')

  module_function

  def resources
    @resources ||= TwitterCldr::Resources::Loader.new
  end

  def get_resource(...)
    resources.get_resource(...)
  end
end
