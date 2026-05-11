# frozen_string_literal: true

module Submissions
  module GenerateVoidedDocuments
    WATERMARK_COLOR = [0.85, 0.10, 0.10].freeze
    WATERMARK_STROKE_OPACITY = 0.85
    WATERMARK_FONT_SIZE = 150
    WATERMARK_STROKE_WIDTH = 2.2
    FOOTER_FONT_SIZE = 10
    FOOTER_HEIGHT = 36

    module_function

    def call(submission)
      return [] unless submission.voided_at?

      submission.with_lock do
        source_documents = source_attachments(submission)
                           .select { |a| a.blob.content_type == 'application/pdf' }
                           .uniq { |a| a.blob.checksum }
        existing = submission.voided_documents.attachments.reload

        return existing.to_a if existing.size == source_documents.size && existing.any?

        submission.voided_documents.purge if existing.any?

        voided_by = submission.voided_by_user
        reason = submission.void_reason
        voided_at = submission.voided_at

        source_documents.each do |source|
          watermarked_io = stamp_pdf(source.download, voided_at:, voided_by:, reason:)

          submission.voided_documents.attach(
            io: watermarked_io,
            filename: build_filename(source.filename),
            content_type: 'application/pdf'
          )
        end
      end

      submission.voided_documents.attachments.reload.to_a
    end

    def source_attachments(submission)
      if submission.documents.attached?
        submission.documents.attachments
      elsif submission.template
        submission.template.documents_attachments.to_a
      else
        []
      end
    end

    def stamp_pdf(pdf_data, voided_at:, voided_by:, reason:)
      doc = HexaPDF::Document.new(io: StringIO.new(pdf_data))

      doc.pages.each do |page|
        draw_watermark_on_page(doc, page)
        draw_footer_on_page(doc, page, voided_at:, voided_by:, reason:)
      end

      out = StringIO.new
      doc.write(out, validate: false)
      out.tap(&:rewind)
    end

    def draw_watermark_on_page(doc, page)
      box = page.box(:media)
      width = box.width
      height = box.height

      font = doc.fonts.add('Helvetica', variant: :bold)
      fragment = HexaPDF::Layout::TextFragment.create(
        'VOIDED',
        font:,
        font_size: WATERMARK_FONT_SIZE,
        stroke_color: WATERMARK_COLOR,
        stroke_width: WATERMARK_STROKE_WIDTH,
        text_rendering_mode: :stroke,
        stroke_alpha: WATERMARK_STROKE_OPACITY
      )
      text_width = fragment.width
      text_height = fragment.height

      canvas = page.canvas(type: :overlay)

      canvas.save_graphics_state do
        center_x = width / 2.0
        center_y = height / 2.0
        angle_rad = Math::PI / 6

        cos_a = Math.cos(angle_rad)
        sin_a = Math.sin(angle_rad)

        offset_x = -(text_width / 2.0) * cos_a + (text_height / 2.0) * sin_a
        offset_y = -(text_width / 2.0) * sin_a - (text_height / 2.0) * cos_a

        canvas.transform(cos_a, sin_a, -sin_a, cos_a, center_x + offset_x, center_y + offset_y)
        fragment.draw(canvas, 0, 0)
      end
    end

    def draw_footer_on_page(doc, page, voided_at:, voided_by:, reason:)
      box = page.box(:media)
      width = box.width

      canvas = page.canvas(type: :overlay)

      canvas.save_graphics_state do
        canvas.fill_color(0.95, 0.20, 0.20)
        canvas.rectangle(0, 0, width, FOOTER_HEIGHT).fill
      end

      font = doc.fonts.add('Helvetica', variant: :bold)
      white = [1.0, 1.0, 1.0]

      line1 = build_footer_line1(voided_at, voided_by)
      line2 = build_footer_line2(reason)

      [line1, line2].each_with_index do |text, idx|
        next if text.blank?

        fragment = HexaPDF::Layout::TextFragment.create(text, font:, font_size: FOOTER_FONT_SIZE,
                                                              fill_color: white)
        canvas.save_graphics_state do
          fragment.draw(canvas, 12, FOOTER_HEIGHT - 14 - (idx * 14))
        end
      end
    end

    def build_footer_line1(voided_at, voided_by)
      timestamp = voided_at.utc.strftime('%Y-%m-%d %H:%M UTC')
      voided_by_label = voided_by ? (voided_by.full_name.presence || voided_by.email) : 'an authorized user'

      "VOIDED on #{timestamp} by #{voided_by_label}"
    end

    def build_footer_line2(reason)
      return nil if reason.blank?

      "Reason: #{reason.to_s.tr("\r\n", ' ').squeeze(' ').strip[0, 200]}"
    end

    def build_filename(original_filename)
      base = original_filename.base.to_s
      ext = original_filename.extension.presence || 'pdf'

      "#{base}-voided.#{ext}"
    end
  end
end
