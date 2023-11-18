# frozen_string_literal: true

module Templates
  module ProcessDocument
    DPI = 200
    FORMAT = '.jpg'
    ATTACHMENT_NAME = 'preview_images'
    SECURED_ATTACHMENT_NAME = 'preview_secured_images'

    PDF_CONTENT_TYPE = 'application/pdf'
    Q = 35
    MAX_WIDTH = 1400
    MAX_NUMBER_OF_PAGES_PROCESSED = 15

    module_function

    def call(attachment, data)
      if attachment.content_type == PDF_CONTENT_TYPE
        generate_pdf_preview_images(attachment, data)
      elsif attachment.image?
        generate_preview_image(attachment, data)
      end

      attachment
    end

    def generate_preview_image(attachment, data)
      ActiveStorage::Attachment.where(name: ATTACHMENT_NAME, record: attachment).destroy_all

      image = Vips::Image.new_from_buffer(data, '')
      image = image.autorot.resize(MAX_WIDTH / image.width.to_f)

      io = StringIO.new(image.write_to_buffer(FORMAT, Q: Q, interlace: true))

      ActiveStorage::Attachment.create!(
        blob: ActiveStorage::Blob.create_and_upload!(
          io:, filename: "0#{FORMAT}",
          metadata: { analyzed: true, identified: true, width: image.width, height: image.height }
        ),
        name: ATTACHMENT_NAME,
        record: attachment
      )
    end

    def generate_pdf_preview_images(attachment, data)
      ActiveStorage::Attachment.where(name: ATTACHMENT_NAME, record: attachment).destroy_all
      number_of_pages = HexaPDF::Document.new(io: StringIO.new(data)).pages.size

      (attachment.metadata['pdf'] ||= {})[:number_of_pages] = number_of_pages

      attachment.save!

      (0..[number_of_pages - 1, MAX_NUMBER_OF_PAGES_PROCESSED].min).each do |page_number|

        page = Vips::Image.new_from_buffer(data, '', dpi: DPI, page: page_number)
        page = page.resize(MAX_WIDTH / page.width.to_f)

        io = StringIO.new(page.write_to_buffer(FORMAT, Q: Q, interlace: true))

        ApplicationRecord.no_touching do
          ActiveStorage::Attachment.create!(
            blob: ActiveStorage::Blob.create_and_upload!(
              io:, filename: "#{page_number}#{FORMAT}",
              metadata: { analyzed: true, identified: true, width: page.width, height: page.height }
            ),
            name: ATTACHMENT_NAME,
            record: attachment
          )
        end
      end
    end

    def generate_pdf_preview_from_file(attachment, file_path, page_number)
      io = StringIO.new

      command = [
        'pdftocairo', '-jpeg', '-jpegopt', "progressive=y,quality=#{Q},optimize=y",
        '-scale-to-x', MAX_WIDTH, '-scale-to-y', '-1',
        '-r', DPI, '-f', page_number + 1, '-l', page_number + 1,
        '-singlefile', Shellwords.escape(file_path), '-'
      ].join(' ')

      Open3.popen3(command) do |_, stdout, _, _|
        io.write(stdout.read)

        io.rewind
      end

      page = Vips::Image.new_from_buffer(io.read, '')

      io.rewind

      ApplicationRecord.no_touching do
        ActiveStorage::Attachment.create!(
          blob: ActiveStorage::Blob.create_and_upload!(
            io:, filename: "#{page_number}#{FORMAT}",
            metadata: { analyzed: true, identified: true, width: page.width, height: page.height }
          ),
          name: ATTACHMENT_NAME,
          record: attachment
        )
      end

      io
    end

    def modify_pdf_data(original_pdf_data, excluded_page_number)
      pdf = HexaPDF::Document.new(io: StringIO.new(original_pdf_data))
      pdf.pages.delete_at(excluded_page_number)
      modified_pdf_data = StringIO.new
      pdf.write(modified_pdf_data)
      modified_pdf_data.string
    end
    
    def create_blob_from_data(data, original_blob)
      original_blob.tap do |blob|
        blob.io = StringIO.new(data)
        blob.filename = original_blob.filename
        blob.save!
      end
    end

    def generate_pdf_secured_preview_images(template, attachment, data)
      ActiveStorage::Attachment.where(name: SECURED_ATTACHMENT_NAME, record: attachment).destroy_all
      number_of_pages = PDF::Reader.new(StringIO.new(data)).pages.size - 1
      (0..number_of_pages).each do |page_number|
        pdf = Vips::Image.new_from_buffer(data, '', dpi: DPI, page: page_number)
        pdf = pdf.resize(MAX_WIDTH / pdf.width.to_f)
        redacted_boxes = template.fields.select { |field| field['type'] == 'redact' && field['areas'][0]['page'] == page_number }
        deleted_page_field = template.fields.select { |field| field['type'] == 'deleted_page' && field['areas'][0]['page'] == page_number }
        if !deleted_page_field.empty?
          modified_pdf_data = modify_pdf_data(data, page_number)
          attachment.blob = create_blob_from_data(modified_pdf_data, attachment.blob)
          template.fields.delete(deleted_page_field)
          template.save!
          next 
        end
        if !redacted_boxes.empty?
          redacted_boxes.each do |box|
            x = (box['areas'][0]['x'] * pdf.width).to_i
            y = (box['areas'][0]['y'] * pdf.height).to_i
            w = (box['areas'][0]['w'] * pdf.width).to_i
            h = (box['areas'][0]['h'] * pdf.height).to_i
            black_rect = Vips::Image.black(w, h)
            pdf = pdf.insert(black_rect, x, y)
          end
        end
        
        io = StringIO.new(pdf.write_to_buffer(FORMAT, Q: Q))
  
        ActiveStorage::Attachment.create!(
          blob: ActiveStorage::Blob.create_and_upload!(
            io: io, filename: "#{page_number}#{FORMAT}",
            metadata: { analyzed: true, identified: true, width: pdf.width, height: pdf.height }
          ),
          name: SECURED_ATTACHMENT_NAME,
          record: attachment
        )
      end
    end

    def delete_picture(template, attachment_id, page_number)
      attachment = ActiveStorage::Attachment.find_by(id: attachment_id)
      return unless attachment
      attachment.purge
      # deleted_page_field = {
      #   'type' => 'deleted_page',
      #   'areas' => [{
      #     'x' => 0,
      #     'y' => 0,
      #     'w' => 1,
      #     'h' => 1
      #     'attachment_uuid' => SecureRandom.uuid,
      #     'page' => page_number,
      #   }]
      # }
      template.fields << deleted_page_field
      template.save!
    end

    def upload_new_blank_image(template, document)
     
      blank_image = generate_blank_image
      blank_blob = create_blob_from_image(blank_image, document )
      # upload_new_attachment(template, blank_blob, ATTACHMENT_NAME)
      # puts '-----New blank image uploaded successfully!-----'
      if blank_blob
       Rails.logger.info('New blank image uploaded successfully!')
      else
        Rails.logger.info('Blank image not uploaded')
      end
    end

   
    def generate_blank_image #gives images when debug
      height = 2000
      Vips::Image.new_from_array([[255]* MAX_WIDTH] * height, 255)
    end


    def create_blob_from_image(image, attachment)
     
      begin
      previews_count = attachment.preview_images.count
      # base_filename = "#{SecureRandom.uuid}_#{previews_count + 1}"
      ActiveStorage::Attachment.create!(
        blob: ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new(image.write_to_buffer(FORMAT, Q: Q, interlace: true)),
        filename: "#{SecureRandom.uuid}#{FORMAT}",
        metadata: { analyzed: true, identified: true, width: image.width, height: image.height }
        ),
        name: ATTACHMENT_NAME,
        record: attachment
      )
      rescue => e
      Rails.logger.error("Error creating blob from image: #{e.message}")
      end
    end


    #   ActiveStorage::Blob.create_and_upload!(
    #     io: StringIO.new(image.write_to_buffer(FORMAT, Q: Q, interlace: true)),
    #     filename: "#{SecureRandom.uuid}#{FORMAT}",
    #     metadata: { analyzed: true, identified: true, width: image.width, height: image.height }
    #   )
    # end
    # def upload_new_attachment(template, blob, attachment_name)
    #   template.documents.attach(blob)
    #   template.documents.last.update!(name: attachment_name)
    # end

  end
end
