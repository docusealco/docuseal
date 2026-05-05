# frozen_string_literal: true

module Templates
  module RemoveTextTags
    PADDING = 0.002

    module_function

    def call(data, tags)
      return data if tags.blank?

      pdf = HexaPDF::Document.new(io: StringIO.new(data))

      tags.group_by { |tag| tag[:area]['page'] }.each do |page_index, page_tags|
        page = pdf.pages[page_index]

        next unless page

        canvas = page.canvas(type: :overlay)
        box = page.box

        page_tags.each do |tag|
          area = tag[:area]
          x = [(area['x'] - PADDING) * box.width, 0].max
          y = box.height - ((area['y'] + area['h'] + PADDING) * box.height)
          w = [(area['w'] + (PADDING * 2)) * box.width, box.width - x].min
          h = (area['h'] + (PADDING * 2)) * box.height

          canvas.fill_color('white').rectangle(x, y, w, h).fill
        end
      end

      io = StringIO.new

      pdf.write(io, incremental: false, validate: false)

      io.string
    end
  end
end
