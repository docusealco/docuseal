# frozen_string_literal: true

module Submitters
  module CreateStampAttachment
    WIDTH = 400
    HEIGHT = 200
    LRM = "\u200E"

    module_function

    def call(submitter, with_logo: true)
      attachment = build_attachment(submitter, with_logo:)

      attachment.save!

      attachment
    end

    def build_attachment(submitter, with_logo: true)
      image = generate_stamp_image(submitter, with_logo:)

      image_data = image.write_to_buffer('.png', strip: true)

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
          ImageUtils.load_vips(load_logo(submitter).read)
        else
          Vips::Image.black(WIDTH, WIDTH, bands: 4).copy(interpretation: :srgb)
        end

      logo = logo.resize([WIDTH / logo.width.to_f, HEIGHT / logo.height.to_f].min)
      logo = logo.copy(interpretation: :srgb) if logo.interpretation == :multiband

      base_layer = Vips::Image.black(WIDTH, HEIGHT).new_from_image([255, 255, 255, 255]).copy(interpretation: :srgb)

      opacity_layer = Vips::Image.black(WIDTH, HEIGHT).new_from_image([255, 255, 255, 127]).copy(interpretation: :srgb)

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
      if submitter.completed_at
        time = I18n.l(submitter.completed_at.in_time_zone(submitter.submission.account.timezone),
                      format: :long,
                      locale: submitter.submission.account.locale)

        timezone = TimeUtils.timezone_abbr(submitter.submission.account.timezone, submitter.completed_at)
      end

      name = build_name(submitter)
      role = build_role(submitter)

      digitally_signed_by = I18n.t(:digitally_signed_by, locale: submitter.submission.account.locale)

      name = ERB::Util.html_escape(name)
      role = ERB::Util.html_escape(role)

      text =
        %(<span size="90">#{LRM}#{digitally_signed_by}:\n#{LRM}<b>#{name}</b>\n#{LRM}#{role}#{time} #{timezone}</span>)

      Vips::Image.text(text, width: WIDTH, height: HEIGHT, wrap: :'word-char')
    end

    def build_name(submitter)
      if submitter.name.present? && submitter.email.present?
        "#{submitter.name} #{submitter.email}"
      else
        submitter.name || submitter.email || submitter.phone
      end
    end

    def build_role(submitter)
      if submitter.submission.template_submitters.size > 1
        item = submitter.submission.template_submitters.find { |e| e['uuid'] == submitter.uuid }

        "#{I18n.t(:role, locale: submitter.account.locale)}: #{item['name']}\n"
      else
        ''
      end
    end

    def load_logo(_submitter)
      PdfIcons.stamp_logo_io
    end
  end
end
