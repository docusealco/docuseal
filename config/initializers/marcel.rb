# frozen_string_literal: true

priority = %w[application/pdf image/jpeg image/png]

indexes = Marcel::MAGIC.each_with_index.with_object({}) do |((type, _), i), acc|
  acc[type] = i if priority.include?(type)

  break acc if acc.size == priority.size
end

pdf_index, jpg_index, png_index = indexes.values_at(*priority)

Marcel::MAGIC[0], Marcel::MAGIC[pdf_index] = Marcel::MAGIC[pdf_index], Marcel::MAGIC[0]
Marcel::MAGIC[1], Marcel::MAGIC[jpg_index] = Marcel::MAGIC[jpg_index], Marcel::MAGIC[1]
Marcel::MAGIC[2], Marcel::MAGIC[png_index] = Marcel::MAGIC[png_index], Marcel::MAGIC[2]
