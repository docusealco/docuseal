# frozen_string_literal: true

module Submitters
  module CreateStampAttachment
    WIDTH = 400
    HEIGHT = 200

    TRANSPARENT_PIXEL = "\x89PNG\r\n\u001A\n\u0000\u0000\u0000\rIHDR\u0000" \
                        "\u0000\u0000\u0001\u0000\u0000\u0000\u0001\b\u0004" \
                        "\u0000\u0000\u0000\xB5\u001C\f\u0002\u0000\u0000\u0000" \
                        "\vIDATx\xDAc\xFC_\u000F\u0000\u0002\x83\u0001\x804\xC3ڨ" \
                        "\u0000\u0000\u0000\u0000IEND\xAEB`\x82"

    module_function

    def call(submitter, with_logo: true)
      attachment = build_attachment(submitter, with_logo:)

      attachment.save!

      attachment
    end

    def build_attachment(submitter, with_logo: true)
      image = generate_stamp_image(submitter, with_logo:)

      image_data = image.write_to_buffer('.png')

      checksum = Digest::MD5.base64digest(image_data)

      attachment = submitter.attachments.joins(:blob).find_by(blob: { checksum: })

      attachment || submitter.attachments_attachments.new(
        blob: ActiveStorage::Blob.create_and_upload!(io: StringIO.new(image_data), filename: 'stamp.png'),
        metadata: { analyzed: true, identified: true, width: image.width, height: image.height }
      )
    end

    def generate_stamp_image(submitter, with_logo: true)
      logo =
        if with_logo
          Vips::Image.new_from_buffer(load_logo(submitter).read, '')
        else
          Vips::Image.new_from_buffer(TRANSPARENT_PIXEL, '').resize(WIDTH)
        end

      logo = logo.resize([WIDTH / logo.width.to_f, HEIGHT / logo.height.to_f].min)

      base_layer = Vips::Image.black(WIDTH, HEIGHT).new_from_image([255, 255, 255]).copy(interpretation: :srgb)

      opacity_layer = Vips::Image.new_from_buffer(TRANSPARENT_PIXEL, '').resize(WIDTH)

      text = build_text_image(submitter)

      text_layer = text.new_from_image([0, 0, 0]).copy(interpretation: :srgb)
      text_layer = text_layer.bandjoin(text)

      base_layer = base_layer.composite(logo, 'over',
                                        x: (WIDTH - logo.width) / 2,
                                        y: (HEIGHT - logo.height) / 2)

      base_layer = base_layer.composite(opacity_layer, 'over')

      base_layer.composite(text_layer, 'over',
                           x: (WIDTH - text_layer.width) / 2,
                           y: (HEIGHT - text_layer.height) / 2)
    end

    def build_text_image(submitter)
      time = I18n.l(submitter.completed_at.in_time_zone(submitter.submission.account.timezone),
                    format: :long,
                    locale: submitter.submission.account.locale)

      timezone = TimeUtils.timezone_abbr(submitter.submission.account.timezone, submitter.completed_at)

      name = if submitter.name.present? && submitter.email.present?
               "#{submitter.name} #{submitter.email}"
             else
               submitter.name || submitter.email || submitter.phone
             end

      role = if submitter.submission.template_submitters.size > 1
               item = submitter.submission.template_submitters.find { |e| e['uuid'] == submitter.uuid }

               "#{I18n.t(:role, locale: submitter.account.locale)}: #{item['name']}\n"
             else
               ''
             end

      digitally_signed_by = I18n.t(:digitally_signed_by, locale: submitter.submission.account.locale)

      name = ERB::Util.html_escape(name)
      role = ERB::Util.html_escape(role)

      text = %(<span size="90">#{digitally_signed_by}:\n<b>#{name}</b>\n#{role}#{time} #{timezone}</span>)

      Vips::Image.text(text, width: WIDTH, height: HEIGHT, wrap: :'word-char')
    end

    def load_logo(_submitter)
      PdfIcons.logo_io
    end
  end
end
