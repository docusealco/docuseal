# frozen_string_literal: true

module Submissions
  module GenerateResultAttachments
    module_function

    def call(submission)
      zip_file = Tempfile.new
      zip_stream = Zip::ZipOutputStream.open(zip_file)

      submission.flow.schema.map do |item|
        document = submission.flow.documents.find { |e| e.uuid == item['attachment_uuid'] }
        field_area_index = Flows.build_field_areas_index(submission.flow)

        document.open do |tempfile|
          pdf = CombinePDF.load(tempfile.path)

          pdf.pages.each_with_index do |page, index|
            blocks = field_area_index.dig(document.uuid, index)

            next if blocks.blank?

            scale = page.page_size[2] / 1400.0

            blocks.each do |block|
              area, field = block.values_at(:area, :field)
              page.textbox(submission.values[field['uuid']],
                           x: (area['x'] * scale) - 10,
                           y: page.page_size[2] - (area['y'] * scale) + 150,
                           width: area['w'] * scale,
                           height: area['h'] * scale)
            end
          end

          string = pdf.to_pdf
          io = StringIO.new(string)

          zip_stream.put_next_entry("#{item['name']}.pdf")
          zip_stream.write(string)

          ActiveStorage::Attachment.create!(
            blob: ActiveStorage::Blob.create_and_upload!(
              io:, filename: "#{item['name']}.pdf"
            ),
            name: 'documents',
            record: submission
          )
        end
      end

      zip_stream.close

      submission.archive.attach(io: zip_file, filename: 'submission.zip')
    end
  end
end
