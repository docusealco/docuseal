# frozen_string_literal: true

# = AsciiDoc
#
# Asciidoctor implementation for AsciiDoc
#
# Asciidoctor is an open source, pure-Ruby processor for
# converting AsciiDoc documents or strings into HTML 5,
# DocBook 4.5 and other formats.
#
# === See also
#
# * http://asciidoc.org
# * http://asciidoctor.github.com

require_relative 'template'
require 'asciidoctor'

Tilt::AsciidoctorTemplate = Tilt::StaticTemplate.subclass do
  @options[:header_footer] = false if @options[:header_footer].nil?
  Asciidoctor.render(@data, @options)
end
