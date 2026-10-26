# frozen_string_literal: true

module Templates
  module BuildPdfiumAnnotations
    URI_PREFIXES = %w[https:// http://].freeze
    LINKS_LIMIT = 250

    module_function

    def call(doc)
      annotations = []

      doc.page_count.times do |page_index|
        break if annotations.size >= LINKS_LIMIT
        next if doc.annot_count(page_index).zero?

        page = doc.get_page(page_index)
        geometry = { box: page.box, rotation: page.rotation }

        page.annotations.each do |annotation|
          next unless annotation.link? && annotation.rect?

          url = annotation.link.url

          next if url.blank? || URI_PREFIXES.none? { |prefix| url.start_with?(prefix) }

          annotations << build_external_link_hash(url, annotation, geometry).merge('page' => page_index)
        end
      end

      annotations
    rescue StandardError => e
      Rollbar.error(e) if defined?(Rollbar)

      raise if Rails.env.development?

      []
    end

    def build_external_link_hash(url, area, geometry)
      x, y, w, h, page_width, page_height = Pdfium.transform_rect(area.bounds, **geometry)

      {
        'type' => 'external_link',
        'value' => url,
        'x' => x / page_width,
        'y' => y / page_height,
        'w' => w / page_width,
        'h' => h / page_height
      }
    end
  end
end
