# frozen_string_literal: true

class PdfProcessor < HexaPDF::Content::Processor
  attr_reader :result, :contents
  attr_accessor :handler

  def initialize(page)
    super

    @contents = ''.b
    @result = []

    @serializer = HexaPDF::Serializer.new
  end

  def process(operator, operands = [])
    super

    contents << @operators[operator].serialize(
      @serializer,
      *handler.call(self, operator, operands)
    )
  end

  def self.call(data, pdf_handler, result_handler, acc = {})
    doc = HexaPDF::Document.new(io: StringIO.new(data))

    doc.pages.each do |page|
      processor = PdfProcessor.new(page)
      processor.handler = pdf_handler

      page.process_contents(processor)

      page.contents = processor.contents

      processor.result.each do |item|
        result_handler.call(item, page, acc)
      end
    end

    new_io = StringIO.new

    doc.write(new_io)

    [new_io.tap(&:rewind).read, acc]
  end
end
