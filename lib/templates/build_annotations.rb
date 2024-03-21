# frozen_string_literal: true

module Templates
  module BuildAnnotations
    module_function

    def call(data)
      pdf = HexaPDF::Document.new(io: StringIO.new(data))

      pdf.pages.flat_map.with_index do |page, index|
        (page[:Annots] || []).filter_map do |annot|
          next if annot.blank?
          next if annot[:A].blank? || annot[:A][:URI].blank?
          next unless annot[:Subtype] == :Link
          next if !annot[:A][:URI].starts_with?('https://') && !annot[:A][:URI].starts_with?('http://')

          build_external_link_hash(page, annot).merge('page' => index)
        end
      end
    rescue StandardError => e
      Rollbar.error(e) if defined?(Rollbar)

      []
    end

    def build_external_link_hash(page, annot)
      left, bottom, right, top = annot[:Rect]

      {
        'type' => 'external_link',
        'value' => annot[:A][:URI],
        'x' => left / page.box.width.to_f,
        'y' => (page.box.height - top) / page.box.height.to_f,
        'w' => (right - left) / page.box.width.to_f,
        'h' => (top - bottom) / page.box.height.to_f
      }
    end
  end
end
