# frozen_string_literal: true

module Submissions
  module GenerateExportFiles
    UnknownFormat = Class.new(StandardError)

    module_function

    def call(submissions, format: :csv)
      rows = build_table_rows(submissions)

      if format.to_sym == :csv
        rows_to_csv(rows)
      elsif format.to_sym == :xlsx
        rows_to_xlsx(rows)
      else
        raise UnknownFormat
      end
    end

    def rows_to_xlsx(rows)
      workbook = RubyXL::Workbook.new
      worksheet = workbook[0]
      worksheet.sheet_name = I18n.l(Time.current.to_date)

      headers = build_headers(rows)
      headers.each_with_index do |column_name, column_index|
        worksheet.add_cell(0, column_index, column_name)
      end

      rows.each.with_index(1) do |row, row_index|
        extract_columns(row, headers).each_with_index do |value, column_index|
          worksheet.add_cell(row_index, column_index, value)
        end
      end

      workbook.stream.string
    end

    def rows_to_csv(rows)
      headers = build_headers(rows)

      CSV.generate do |csv|
        csv << headers

        rows.each do |row|
          csv << extract_columns(row, headers)
        end
      end
    end

    def build_headers(rows)
      rows.reduce(Set.new) { |acc, row| acc + row.pluck(:name) }
    end

    def extract_columns(row, headers)
      headers.map { |key| row.find { |e| e[:name] == key }&.dig(:value) }
    end

    def build_table_rows(submissions)
      submissions.map do |submission|
        submission_data = []
        submitters_count = submission.submitters.size

        submission.submitters.each do |submitter|
          template_submitters = submission.template_submitters || submission.template.submitters
          submitter_name = template_submitters.find { |s| s['uuid'] == submitter.uuid }['name']

          submission_data += build_submission_data(submitter, submitter_name, submitters_count)

          submission_data += submitter_formatted_fields(submitter).map do |field|
            {
              name: column_name(field[:name], submitter_name, submitters_count),
              value: field[:value]
            }
          end

          next if submitter != submission.submitters.select(&:completed_at?).max_by(&:completed_at)

          submission_data += submitter.documents.map.with_index(1) do |attachment, index|
            {
              name: "Document #{index}",
              value: ActiveStorage::Blob.proxy_url(attachment.blob)
            }
          end
        end

        submission_data
      end
    end

    def build_submission_data(submitter, submitter_name, submitters_count)
      [
        {
          name: column_name('Name', submitter_name, submitters_count),
          value: submitter.name
        },
        {
          name: column_name('Email', submitter_name, submitters_count),
          value: submitter.email
        },
        {
          name: column_name('Phone', submitter_name, submitters_count),
          value: submitter.phone
        },
        {
          name: column_name('Completed At', submitter_name, submitters_count),
          value: submitter.completed_at
        }
      ].reject { |e| e[:value].blank? }
    end

    def column_name(name, submitter_name, submitters_count = 1)
      submitters_count > 1 ? "#{submitter_name} - #{name}" : name
    end

    def submitter_formatted_fields(submitter)
      fields = submitter.submission.template_fields || submitter.submission.template.fields

      template_fields = fields.select { |f| f['submitter_uuid'] == submitter.uuid }

      attachments_index = submitter.attachments.index_by(&:uuid)

      template_field_counters = Hash.new { 0 }
      template_fields.map do |template_field|
        submitter_value = submitter.values.fetch(template_field['uuid'], nil)
        template_field_type = template_field['type']
        template_field_counters[template_field_type] += 1
        template_field_name = template_field['name'].presence
        template_field_name ||= "#{template_field_type.titleize} Field #{template_field_counters[template_field_type]}"

        value =
          if template_field_type.in?(%w[image signature])
            attachment = attachments_index[submitter_value]
            ActiveStorage::Blob.proxy_url(attachment.blob) if attachment
          elsif template_field_type == 'file'
            Array.wrap(submitter_value).compact_blank.filter_map do |e|
              attachment = attachments_index[e]
              ActiveStorage::Blob.proxy_url(attachment.blob) if attachment
            end
          else
            submitter_value
          end

        { name: template_field_name, uuid: template_field['uuid'], value: }
      end
    end
  end
end
