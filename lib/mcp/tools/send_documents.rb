# frozen_string_literal: true

module Mcp
  module Tools
    module SendDocuments
      SUBMITTER_KEYS = %w[
        email name phone role completed external_id
        metadata values readonly_fields message fields
      ].freeze

      SCHEMA = {
        name: 'send_documents',
        title: 'Send Documents',
        description: 'Send a document template for signing to specified submitters',
        inputSchema: {
          type: 'object',
          properties: {
            template_id: {
              type: 'integer',
              description: 'Template identifier'
            },
            submitters: {
              type: 'array',
              description: 'The list of submitters (signers)',
              items: {
                type: 'object',
                properties: {
                  email: {
                    type: 'string',
                    description: 'Submitter email address'
                  },
                  name: {
                    type: 'string',
                    description: 'Submitter name'
                  },
                  phone: {
                    type: 'string',
                    description: 'Submitter phone number in E.164 format'
                  },
                  role: {
                    type: 'string',
                    description: 'Template role name (required when the template has multiple roles)'
                  },
                  completed: {
                    type: 'boolean',
                    description: 'Mark this submitter as already completed (skips the signing UI)'
                  },
                  external_id: {
                    type: 'string',
                    description: 'Your application identifier for this submitter'
                  },
                  metadata: {
                    type: 'object',
                    description: 'Arbitrary key/value metadata stored on the submitter',
                    additionalProperties: true
                  },
                  values: {
                    type: 'object',
                    description: 'Pre-fill field values, keyed by field UUID or field name',
                    additionalProperties: true
                  },
                  readonly_fields: {
                    type: 'array',
                    description: 'Field names to mark read-only for this submitter',
                    items: { type: 'string' }
                  },
                  message: {
                    type: 'object',
                    description: 'Custom email subject/body sent to this submitter',
                    properties: {
                      subject: { type: 'string' },
                      body: { type: 'string' }
                    }
                  },
                  fields: {
                    type: 'array',
                    description: 'Per-field overrides (default_value, title, required, validation, etc.)',
                    items: {
                      type: 'object',
                      properties: {
                        name: { type: 'string', description: 'Field name as defined in the template' },
                        uuid: { type: 'string', description: 'Field UUID (use instead of name to target a specific field)' },
                        default_value: { description: 'Pre-filled value the submitter can still edit; string or array depending on field type' },
                        value: { description: 'Locked value (cannot be edited); string or array depending on field type' },
                        title: { type: 'string' },
                        description: { type: 'string' },
                        readonly: { type: 'boolean' },
                        required: { type: 'boolean' },
                        validation_pattern: { type: 'string' },
                        invalid_message: { type: 'string' }
                      }
                    }
                  }
                }
              }
            }
          },
          required: %w[template_id submitters]
        },
        annotations: {
          readOnlyHint: false,
          destructiveHint: false,
          idempotentHint: false,
          openWorldHint: true
        }
      }.freeze

      module_function

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def call(arguments, current_user, current_ability)
        template = Template.accessible_by(current_ability).find_by(id: arguments['template_id'])

        return { content: [{ type: 'text', text: 'Template not found' }], isError: true } unless template

        current_ability.authorize!(:create, Submission.new(template:, account_id: current_user.account_id))

        return { content: [{ type: 'text', text: 'Template has no fields' }], isError: true } if template.fields.blank?

        submitters = (arguments['submitters'] || []).map do |s|
          s.slice(*SUBMITTER_KEYS).compact.with_indifferent_access
        end

        submissions_attrs = [{ submitters: submitters }.with_indifferent_access]

        Submissions::NormalizeParamUtils.normalize_submissions_params!(submissions_attrs, template, purpose: :api)

        submissions = Submissions.create_from_submitters(
          template:,
          user: current_user,
          source: :api,
          submitters_order: 'random',
          submissions_attrs:,
          params: { 'send_email' => true, 'submitters' => submitters }
        )

        if submissions.blank?
          return { content: [{ type: 'text', text: 'No valid submitters provided' }], isError: true }
        end

        WebhookUrls.enqueue_events(submissions, 'submission.created')

        Submissions.send_signature_requests(submissions)

        submissions.each do |submission|
          submission.submitters.each do |submitter|
            next unless submitter.completed_at?

            ProcessSubmitterCompletionJob.perform_async('submitter_id' => submitter.id,
                                                        'send_invitation_email' => false)
          end
        end

        SearchEntries.enqueue_reindex(submissions)

        submission = submissions.first

        {
          content: [
            {
              type: 'text',
              text: {
                id: submission.id,
                status: 'pending'
              }.to_json
            }
          ]
        }
      rescue Submitters::NormalizeValues::BaseError, Submissions::CreateFromSubmitters::BaseError,
             DownloadUtils::UnableToDownload => e
        { content: [{ type: 'text', text: e.message }], isError: true }
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
    end
  end
end
