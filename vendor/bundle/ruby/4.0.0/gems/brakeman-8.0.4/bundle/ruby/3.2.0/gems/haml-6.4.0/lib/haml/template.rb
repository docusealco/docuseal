# frozen_string_literal: false
require 'temple'
require 'haml/engine'
require 'haml/helpers'

module Haml
  Template = Temple::Templates::Tilt.create(
    Haml::Engine,
    register_as: [:haml, :haml],
  )

  module TemplateExtension
    # Activate Haml::Helpers for tilt templates.
    # https://github.com/judofyr/temple/blob/v0.7.6/lib/temple/mixins/template.rb#L7-L11
    def compile(*)
      "extend Haml::Helpers; #{super}"
    end
  end
  Template.send(:extend, TemplateExtension)
end
