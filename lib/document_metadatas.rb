# frozen_string_literal: true

module DocumentMetadatas
  module_function

  def find_or_create_for_document(document, account_id:)
    checksum = document.blob.checksum

    metadata   = DocumentMetadata.find_by(account_id:, blob_checksum: checksum)
    metadata ||= DocumentMetadata.create!(account_id:, blob_checksum: checksum, text_runs: build_text_runs(document))

    metadata
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def build_text_runs(document)
    number_of_pages = document.metadata.dig('pdf', 'number_of_pages').to_i

    return {} if number_of_pages.zero?

    Pdfium::Document.open_bytes(document.download) do |doc|
      (0...doc.page_count).each_with_object({}) do |page_index, acc|
        page = doc.get_page(page_index)

        acc[page_index] = page.text_objects.map do |node|
          { text: node.content, x: node.x, y: node.y, w: node.w, h: node.h, font_size: node.font_size }
        end
      ensure
        page&.close
      end
    end
  end
end
