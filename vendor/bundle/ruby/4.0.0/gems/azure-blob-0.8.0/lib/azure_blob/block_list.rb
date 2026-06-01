# frozen_string_literal: true

require "rexml"

module AzureBlob
  class BlockList # :nodoc:
    # Internal
    # BlockList builds the XML list of blocks to commit to a blob
    include REXML
    def initialize(blocks)
      @blocks = blocks
      @document = build_document
    end

    def to_s
      document.to_s
    end

    private

    attr_reader :blocks, :document

    def build_document
      document = Document.new
      document.add(XMLDecl.new("1.0", "utf-8"))
      block_list = document.add_element(Element.new("BlockList"))
      blocks.each do |block_id|
        block = block_list.add_element(Element.new("Latest"))
        block.text = block_id
      end
      document
    end
  end
end
