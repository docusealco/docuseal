# frozen_string_literal: true

module Templates
  module BuildAnnotations
    module_function

    def call(data)
      pdf = PDF::Reader.new(StringIO.new(data))

      pdf.pages.flat_map.with_index do |page, index|
        annotations = page.objects.deref!(page.attributes[:Annots]) || []
        annotations.filter_map do |annot|
          next if annot[:A].blank? || annot[:A][:URI].blank?
          next unless annot[:Subtype] == :Link
          next if !annot[:A][:URI].starts_with?('https://') && !annot[:A][:URI].starts_with?('http://')

          build_external_link_hash(page, annot).merge('page' => index)
        end
      end
    end

    def build_external_link_hash(page, annot)
      left, bottom, right, top = annot[:Rect]

      {
        'type' => 'external_link',
        'value' => annot[:A][:URI],
        'x' => left / page.width,
        'y' => (page.height - top) / page.height,
        'w' => (right - left) / page.width,
        'h' => (top - bottom) / page.height
      }
    end
  end
end
