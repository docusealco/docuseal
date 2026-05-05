# frozen_string_literal: true

module Templates
  module RemoveTextTags
    PADDING = 0.002

    module_function

    def call(data, tags)
      return data if tags.blank?

      pdf = HexaPDF::Document.new(io: StringIO.new(data))

      cover_tags(pdf, tags)
      write_pdf(pdf)
    end

    def cover_tags(pdf, tags)
      tags.group_by { |tag| tag[:area]['page'] }.each do |page_index, page_tags|
        page = pdf.pages[page_index]

        next unless page

        page_tags.each { |tag| cover_tag(page, tag) }
      end
    end

    def cover_tag(page, tag)
      page.canvas(type: :overlay)
          .fill_color('white')
          .rectangle(*tag_rect(page.box, tag[:area]))
          .fill
    end

    def tag_rect(box, area)
      x = [(area['x'] - PADDING) * box.width, 0].max
      y = box.height - ((area['y'] + area['h'] + PADDING) * box.height)
      w = [(area['w'] + (PADDING * 2)) * box.width, box.width - x].min
      h = (area['h'] + (PADDING * 2)) * box.height

      [x, y, w, h]
    end

    def write_pdf(pdf)
      io = StringIO.new

      pdf.write(io, incremental: false, validate: false)

      io.string
    end
  end
end
