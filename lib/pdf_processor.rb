# frozen_string_literal: true

class PdfProcessor < HexaPDF::Content::Processor
  attr_accessor :handler, :serializer

  class ParseTextHandler
    attr_accessor :pos, :num, :search_chars, :handler

    def initialize(handler)
      @num = 0
      @pos = 0

      @handler = handler
      @search_chars = handler.search_chars
    end

    TJS = %i[TJ Tj].freeze

    def call(processor, operator, operands)
      return unless TJS.include?(operator)

      processor.send(:decode_text, *operands).chars.each do |char|
        handler.tokens << [char, [@num, @pos]] if search_chars.include?(char)

        @pos += 1
      end

      @pos = 0
      @num += 1
    rescue HexaPDF::Error => e
      Rails.logger.error(e.message)

      @pos = 0
      @num += 1
    end
  end

  def initialize(page)
    super

    @serializer = HexaPDF::Serializer.new
  end

  def serialize(operator, operands)
    operators[operator].serialize(serializer, *operands)
  end

  def process(operator, operands = [])
    super

    handler.call(self, operator, operands)
  end

  def self.call(data, process_handler, result_handler, acc = {}, remove_tags: true)
    doc = HexaPDF::Document.new(io: StringIO.new(data))

    doc.pages.each do |page|
      processor = PdfProcessor.new(page)
      process_handler_instance = process_handler.new
      processor.handler = ParseTextHandler.new(process_handler_instance)

      page.process_contents(processor)

      if process_handler_instance.tokens?
        processor = PdfProcessor.new(page)
        processor.handler = process_handler_instance

        page.process_contents(processor)

        page.contents = process_handler_instance.contents if process_handler_instance.result.present? && remove_tags
      end

      page[:Annots].to_a.each do |annot|
        next unless annot

        text = annot[:Contents].to_s.squish

        next unless text.starts_with?('{{') && text.ends_with?('}}')

        result_handler.call({ text:, rect: annot[:Rect] }, page, acc)

        page[:Annots].delete(annot)
      end

      process_handler_instance.result.each do |item|
        result_handler.call(item, page, acc)
      end
    end

    new_io = StringIO.new

    doc.write(new_io, validate: false)

    [new_io.tap(&:rewind).read, acc]
  end
end
