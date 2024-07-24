# frozen_string_literal: true

module Submissions
  module GenerateAuditTrail
    FONT_SIZE = 9
    TEXT_COLOR = '525252'
    FONT_PATH = '/fonts/GoNotoKurrent-Regular.ttf'
    FONT_BOLD_PATH = '/fonts/GoNotoKurrent-Bold.ttf'
    FONT_NAME = if File.exist?(FONT_PATH)
                  'GoNotoKurrent'
                else
                  'Helvetica'
                end

    VERIFIED_TEXT = 'Verified'
    UNVERIFIED_TEXT = 'Unverified'

    CURRENCY_SYMBOLS = {
      'USD' => '$',
      'EUR' => '€',
      'GBP' => '£'
    }.freeze

    RTL_REGEXP = TextUtils::RTL_REGEXP
    MAX_IMAGE_HEIGHT = 100

    US_TIMEZONES = %w[EST CST MST PST HST AKDT].freeze

    module_function

    # rubocop:disable Metrics
    def call(submission)
      document = build_audit_trail(submission)

      account = submission.account

      pkcs = Accounts.load_signing_pkcs(account)
      tsa_url = Accounts.load_timeserver_url(account)

      io = StringIO.new

      document.trailer.info[:Creator] = "#{Docuseal.product_name} (#{Docuseal::PRODUCT_URL})"

      sign_params = {
        reason: sign_reason,
        **Submissions::GenerateResultAttachments.build_signing_params(pkcs, tsa_url)
      }

      document.sign(io, **sign_params)

      Submissions::GenerateResultAttachments.maybe_enable_ltv(io, sign_params)

      ActiveStorage::Attachment.create!(
        blob: ActiveStorage::Blob.create_and_upload!(
          io: io.tap(&:rewind), filename: "Audit Log - #{submission.template.name}.pdf"
        ),
        name: 'audit_trail',
        record: submission
      )
    end

    def build_audit_trail(submission)
      account = submission.account
      verify_url = Rails.application.routes.url_helpers.settings_esign_url(**Docuseal.default_url_options)
      page_size =
        if TimeUtils.timezone_abbr(account.timezone, Time.current.beginning_of_year).in?(US_TIMEZONES)
          :Letter
        else
          :A4
        end

      composer = HexaPDF::Composer.new(skip_page_creation: true)
      composer.document.task(:pdfa) if FONT_NAME == 'GoNotoKurrent'

      composer.document.config['font.map'] = {
        'Helvetica' => {
          none: FONT_PATH,
          bold: FONT_BOLD_PATH
        },
        FONT_NAME => {
          none: FONT_PATH,
          bold: FONT_BOLD_PATH
        }
      }

      composer.document.config['font.on_missing_glyph'] =
        Submissions::GenerateResultAttachments.method(:on_missing_glyph).to_proc

      divider = HexaPDF::Layout::Box.create(
        margin: [0, 0, 15, 0],
        border: {
          width: [1, 0, 0, 0],
          color: %w[hp-gray-light]
        },
        height: 1
      )

      composer.page_style(:default, page_size:) do |canvas, style|
        box = canvas.context.box(:media)
        canvas.save_graphics_state do
          canvas.fill_color('FAF7F5')
                .rectangle(0, 0, box.width, 20)
                .rectangle(0, box.height - 20, box.width, 20)
                .fill

          maybe_add_background(canvas, submission, page_size)
        end
        style.frame = style.create_frame(canvas.context, 50)
      end

      composer.style(:base, font: FONT_NAME, font_size: FONT_SIZE, fill_color: TEXT_COLOR, line_spacing: 1)
      composer.style(:link, fill_color: 'hp-blue-light', underline: true)

      composer.new_page

      composer.column(columns: 1) do |column|
        add_logo(column, submission)

        column.text(account.testing? ? 'Testing Log - Not for Production Use' : 'Audit Log',
                    font_size: 16,
                    padding: [10, 0, 0, 0],
                    position: :float, text_align: :right)
      end

      composer.column(columns: 1) do |column|
        column.text("Envelope ID: #{submission.id}", font_size: 12, padding: [15, 0, 8, 0], position: :float)

        unless submission.source.in?(%w[embed api])
          column.formatted_text([{ link: verify_url, text: 'Verify', style: :link }],
                                font_size: 9, padding: [15, 0, 10, 0], position: :float, text_align: :right)
        end
      end

      composer.draw_box(divider)

      last_submitter = submission.submitters.where.not(completed_at: nil).order(:completed_at).last

      documents_data = Submitters.select_attachments_for_download(last_submitter).map do |document|
        original_documents = submission.template.documents.select do |e|
          e.uuid == (document.metadata['original_uuid'] || document.uuid)
        end.presence

        original_documents ||= submission.template.documents.select do |e|
          e.image? && submission.template_schema.any? do |item|
            item['attachment_uuid'] == e.uuid
          end
        end

        link =
          ActiveStorage::Blob.proxy_url(document.blob)

        [
          composer.document.layout.formatted_text_box(
            [{ text: document.filename.to_s, link: }]
          ),
          composer.document.layout.formatted_text_box(
            [
              { text: "Original SHA256:\n", font: [FONT_NAME, { variant: :bold }] },
              original_documents.map { |d| d.metadata['sha256'] || d.checksum }.join("\n"),
              "\n",
              { text: "Result SHA256:\n", font: [FONT_NAME, { variant: :bold }] },
              document.metadata['sha256'] || document.checksum,
              "\n",
              { text: 'Generated at: ', font: [FONT_NAME, { variant: :bold }] },
              "#{I18n.l(document.created_at.in_time_zone(account.timezone), format: :long, locale: account.locale)} " \
              "#{TimeUtils.timezone_abbr(account.timezone, document.created_at)}"
            ], line_spacing: 1.3
          )
        ]
      end

      if documents_data.present?
        composer.table(documents_data, cell_style: { padding: [0, 0, 20, 0], border: { width: 0 } })

        composer.draw_box(divider)
      end

      submission.template_submitters.filter_map do |item|
        submitter = submission.submitters.find { |e| e.uuid == item['uuid'] }

        next if submitter.blank?

        completed_event =
          submission.submission_events.find { |e| e.submitter_id == submitter.id && e.complete_form? } ||
          SubmissionEvent.new

        click_email_event =
          submission.submission_events.find { |e| e.submitter_id == submitter.id && e.click_email? }
        is_phone_verified =
          submission.template_fields.any? do |e|
            e['type'] == 'phone' && e['submitter_uuid'] == submitter.uuid && submitter.values[e['uuid']].present?
          end

        submitter_field_counters = Hash.new { 0 }

        info_rows = [
          [
            composer.document.layout.formatted_text_box(
              [
                submission.template_submitters.size > 1 && { text: "#{item['name']}\n" },
                submitter.email && { text: "#{submitter.email}\n", font: [FONT_NAME, { variant: :bold }] },
                submitter.name && { text: "#{TextUtils.maybe_rtl_reverse(submitter.name)}\n" },
                submitter.phone && { text: "#{submitter.phone}\n" }
              ].compact_blank, line_spacing: 1.3, padding: [0, 20, 0, 0]
            )
          ],
          [
            composer.document.layout.formatted_text_box(
              [
                submitter.email && click_email_event && {
                  text: "Email verification: #{VERIFIED_TEXT}\n"
                },
                submitter.phone && is_phone_verified && {
                  text: "Phone verification: #{VERIFIED_TEXT}\n"
                },
                completed_event.data['ip'] && { text: "IP: #{completed_event.data['ip']}\n" },
                completed_event.data['sid'] && { text: "Session ID: #{completed_event.data['sid']}\n" },
                completed_event.data['ua'] && { text: "User agent: #{completed_event.data['ua']}\n" },
                "\n"
              ].compact_blank, line_spacing: 1.3, padding: [10, 20, 20, 0]
            )
          ]
        ]

        composer.table(info_rows, cell_style: { padding: [0, 0, 0, 0], border: { width: 0 } })

        submission.template_fields.filter_map do |field|
          next if field['submitter_uuid'] != submitter.uuid
          next if field['type'] == 'heading'

          submitter_field_counters[field['type']] += 1

          value = submitter.values[field['uuid']]

          next if Array.wrap(value).compact_blank.blank?

          field_name = field['title'].presence || field['name'].to_s

          [
            composer.formatted_text_box(
              [
                {
                  text: TextUtils.maybe_rtl_reverse(field_name).upcase.presence ||
                        "#{field['type']} Field #{submitter_field_counters[field['type']]}\n".upcase,
                  font_size: 6
                }
              ].compact_blank,
              text_align: field_name.to_s.match?(RTL_REGEXP) ? :right : :left,
              line_spacing: 1.3, padding: [0, 0, 2, 0]
            ),
            if field['type'].in?(%w[image signature initials stamp])
              attachment = submitter.attachments.find { |a| a.uuid == value }
              image = Vips::Image.new_from_buffer(attachment.download, '').autorot

              scale = [600.0 / image.width, 600.0 / image.height].min

              resized_image = image.resize([scale, 1].min)
              io = StringIO.new(resized_image.write_to_buffer('.png'))

              width = field['type'] == 'initials' ? 100 : 200
              height = resized_image.height * (width.to_f / resized_image.width)

              if height > MAX_IMAGE_HEIGHT
                width = (MAX_IMAGE_HEIGHT / height) * width
                height = MAX_IMAGE_HEIGHT
              end

              composer.image(io, width:, height:, margin: [5, 0, 10, 0])
              composer.formatted_text_box([{ text: '' }])
            elsif field['type'].in?(%w[file payment])
              if field['type'] == 'payment'
                unit = CURRENCY_SYMBOLS[field['preferences']['currency']] || field['preferences']['currency']

                price = ApplicationController.helpers.number_to_currency(field['preferences']['price'], unit:)

                composer.formatted_text_box([{ text: "Paid #{price}\n" }], padding: [0, 0, 10, 0])
              end

              composer.formatted_text_box(
                Array.wrap(value).map do |uuid|
                  attachment = submitter.attachments.find { |a| a.uuid == uuid }
                  link =
                    ActiveStorage::Blob.proxy_url(attachment.blob)

                  { link:, text: "#{attachment.filename}\n", style: :link }
                end,
                padding: [0, 0, 10, 0]
              )
            elsif field['type'] == 'checkbox'
              composer.formatted_text_box([{ text: value.to_s.titleize }], padding: [0, 0, 10, 0])
            else
              if field['type'] == 'date'
                value = TimeUtils.format_date_string(value, field.dig('preferences', 'format'), account.locale)
              end

              value = NumberUtils.format_number(value, field.dig('preferences', 'format')) if field['type'] == 'number'

              value = value.join(', ') if value.is_a?(Array)

              composer.formatted_text_box([{ text: TextUtils.maybe_rtl_reverse(value.to_s.presence || 'n/a') }],
                                          text_align: value.to_s.match?(RTL_REGEXP) ? :right : :left,
                                          padding: [0, 0, 10, 0])
            end
          ]
        end

        composer.draw_box(divider)
      end

      composer.text('Event Log', font_size: 12, padding: [10, 0, 20, 0])

      events_data = submission.submission_events.sort_by(&:event_timestamp).map do |event|
        submitter = submission.submitters.find { |e| e.id == event.submitter_id }
        [
          "#{I18n.l(event.event_timestamp.in_time_zone(account.timezone), format: :long, locale: account.locale)} " \
          "#{TimeUtils.timezone_abbr(account.timezone, event.event_timestamp)}",
          composer.document.layout.formatted_text_box(
            [
              { text: SubmissionEvents::EVENT_NAMES[event.event_type.to_sym],
                font: [FONT_NAME, { variant: :bold }] },
              event.event_type.include?('send_') ? ' to ' : ' by ',
              if event.event_type.include?('sms') || event.event_type.include?('phone')
                event.data['phone'] || submitter.phone
              else
                submitter.name || submitter.email || submitter.phone
              end
            ]
          )
        ]
      end

      composer.table(events_data, cell_style: { padding: [0, 0, 12, 0], border: { width: 0 } }) if events_data.present?

      composer.document
    end

    def sign_reason
      'Signed with DocuSeal.co'
    end

    def maybe_add_background(_canvas, _submission, _page_size); end

    def add_logo(column, _submission = nil)
      column.image(PdfIcons.logo_io, width: 40, height: 40, position: :float)

      column.formatted_text([{ text: 'DocuSeal',
                               link: Docuseal::PRODUCT_URL }],
                            font_size: 20,
                            font: [FONT_NAME, { variant: :bold }],
                            width: 100,
                            padding: [5, 0, 0, 8],
                            position: :float, text_align: :left)
    end
    # rubocop:enable Metrics
  end
end
