# frozen_string_literal: true

# = Prawn
#
# Prawn template implementation.
#
# === See also
#
# * http://prawnpdf.org
#
# === Related module
#
# * Tilt::PrawnTemplate

require_relative 'template'
require 'prawn'

module Tilt
  class PrawnTemplate < Template
    self.default_mime_type = 'application/pdf'

    def prepare
      @options[:page_size] = 'A4' unless @options.has_key?(:page_size)
      @options[:page_layout] = :portrait unless @options.has_key?(:page_layout)
    end

    def evaluate(scope, locals, &block)
      pdf = ::Prawn::Document.new(@options)
      locals = locals.dup
      locals[:pdf] = pdf
      super
      pdf.render
    end

    def precompiled_template(locals)
      @data.to_str
    end
  end
end
