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

    def generate_pdf_secured_preview_images(template, attachment, data)
      ActiveStorage::Attachment.where(name: SECURED_ATTACHMENT_NAME, record: attachment).destroy_all
      number_of_pages = PDF::Reader.new(StringIO.new(data)).pages.size - 1
      (0..number_of_pages).each do |page_number|
        pdf = Vips::Image.new_from_buffer(data, '', dpi: DPI, page: page_number)
        pdf = pdf.resize(MAX_WIDTH / pdf.width.to_f)
        redacted_boxes = template.fields.select { |field| field['type'] == 'redact' && field['areas'][0]['page'] == page_number }
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

    def delete_picture(template, document, image_attachment_id, page_number)
      image_attachment = ActiveStorage::Attachment.find_by(id: image_attachment_id)
      return unless image_attachment
      file_path =
      if document.service.name == :disk
        ActiveStorage::Blob.service.path_for(document.key)
      end
      temp_dir = "#{Rails.root}/tmp/"
      FileUtils.mkdir_p(temp_dir)
      temp_file_path = "#{temp_dir}#{SecureRandom.uuid}.pdf"
      File.open(temp_file_path, 'wb') do |file|
        document.download { |chunk| file.write(chunk) }
      end
      pdf = HexaPDF::Document.open(temp_file_path)
      pdf.pages.delete_at(page_number)
      pdf.write(temp_file_path)
      document.reload
      document.metadata[:pdf]['number_of_pages'] -= 1
      temp_doc = document.metadata
      new_attachment = document.attachments.update!(
        name: document.name, 
        uuid: document.uuid,
        blob: ActiveStorage::Blob.create_and_upload!(
          io: File.open(temp_file_path),
          filename: document.blob.filename,
          content_type: document.blob.content_type,
          metadata: temp_doc
        )
      )
      document.blob.purge
      image_attachment.purge
      document.reload
      File.delete(temp_file_path)

      remaining_images = document.preview_images
      remaining_images.each_with_index do |image, index|
        new_filename = "#{index}.jpg"
        image.blob.update!(filename: new_filename)
      end
    rescue StandardError => e
      Rails.logger.error("Error uploading new blank image: #{e.message}")
    ensure
      File.delete(temp_file_path) if File.exist?(temp_file_path)
    end

    def upload_new_blank_image(template, document)
      file_path =
        if document.service.name == :disk
          ActiveStorage::Blob.service.path_for(document.key)
        end
      temp_dir = "#{Rails.root}/tmp/"
      FileUtils.mkdir_p(temp_dir)
      temp_file_path = "#{temp_dir}#{SecureRandom.uuid}.pdf"
      File.open(temp_file_path, 'wb') do |file|
        document.download { |chunk| file.write(chunk) }
      end
      pdf = HexaPDF::Document.open(temp_file_path)
      existing_page_width = pdf.pages[0][:MediaBox][2]
      new_blank_page = pdf.pages.add
      new_blank_page[:MediaBox][2] = existing_page_width
      pdf.write(temp_file_path)
      document.reload
      document.metadata[:pdf]['number_of_pages'] += 1
      temp_doc = document.metadata
      new_attachment = document.attachments.update!(
        name: document.name, 
        uuid: document.uuid,
        blob: ActiveStorage::Blob.create_and_upload!(
          io: File.open(temp_file_path),
          filename: document.blob.filename,
          content_type: document.blob.content_type,
          metadata: temp_doc
        )
      )
      document.blob.purge
      document.reload

      # to update pdf images in storage blob
      self.generate_pdf_preview_images(document, document.blob.download)

      File.delete(temp_file_path)
    rescue StandardError => e
      Rails.logger.error("Error uploading new blank image: #{e.message}")
    ensure
      File.delete(temp_file_path) if File.exist?(temp_file_path)
    end

  end
end
