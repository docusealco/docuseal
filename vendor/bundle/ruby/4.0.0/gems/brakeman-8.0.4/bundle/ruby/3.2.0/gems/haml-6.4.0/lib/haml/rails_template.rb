# frozen_string_literal: true
require 'temple'
require 'haml/engine'
require 'haml/rails_helpers'
require 'haml/util'

module Haml
  class RailsTemplate
    # Compatible with: https://github.com/judofyr/temple/blob/v0.7.7/lib/temple/mixins/options.rb#L15-L24
    class << self
      def options
        @options ||= {
          generator:     Temple::Generators::RailsOutputBuffer,
          use_html_safe: true,
          streaming:     true,
          buffer_class:  'ActionView::OutputBuffer',
          disable_capture: true,
        }
      end

      def set_options(opts)
        options.update(opts)
      end
    end

    def call(template, source = nil)
      source ||= template.source
      options = RailsTemplate.options

      # Make the filename available in parser etc.
      if template.respond_to?(:identifier)
        options = options.merge(filename: template.identifier)
      end

      # https://github.com/haml/haml/blob/4.0.7/lib/haml/template/plugin.rb#L19-L20
      # https://github.com/haml/haml/blob/4.0.7/lib/haml/options.rb#L228
      if template.respond_to?(:type) && template.type == 'text/xml'
        options = options.merge(format: :xhtml)
      end

      if ActionView::Base.try(:annotate_rendered_view_with_filenames) && template.format == :html
        options = options.merge(
          preamble: "<!-- BEGIN #{template.short_identifier} -->",
          postamble: "<!-- END #{template.short_identifier} -->",
        )
      end

      Engine.new(options).call(source)
    end

    def supports_streaming?
      RailsTemplate.options[:streaming]
    end
  end
  ActionView::Template.register_template_handler(:haml, RailsTemplate.new)
end

# Haml extends Haml::Helpers in ActionView each time.
# It costs much, so Haml includes a compatible module at first.
ActiveSupport.on_load(:action_view) do
  include Haml::RailsHelpers
end
