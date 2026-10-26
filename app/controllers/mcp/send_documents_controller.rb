# frozen_string_literal: true

module Mcp
  class SendDocumentsController < McpBaseController
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
                  description: 'Signing role name from the template'
                },
                fields: {
                  type: 'array',
                  description: 'Prefill field values for this submitter (fields become readonly)',
                  items: {
                    type: 'object',
                    properties: {
                      name: {
                        type: 'string',
                        description: 'Field name'
                      },
                      value: {
                        description: 'Prefilled value for the field'
                      }
                    },
                    required: %w[name value]
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
        destructiveHint: true,
        idempotentHint: false,
        openWorldHint: true
      }
    }.freeze

    # rubocop:disable Metrics
    def call
      @template = Template.accessible_by(current_ability).find(mcp_params['template_id'])

      authorize!(:read, @template)

      return render_tool_error('Template has been archived') if @template.archived_at?

      authorize!(:create, Submission.new(template: @template, account_id: current_user.account_id))

      return render_tool_error('Template has no fields') if @template.fields.blank?

      submitters = (mcp_params['submitters'] || []).map do |s|
        attrs = s.slice('email', 'name', 'role', 'phone').compact_blank

        fields = Array.wrap(s['fields']).filter_map do |f|
          next if f['name'].blank?

          { 'name' => f['name'], 'default_value' => f['value'], 'readonly' => true }
        end

        attrs['fields'] = fields if fields.present?

        attrs.with_indifferent_access
      end

      submissions = Submissions.create_from_submitters(
        template: @template,
        user: current_user,
        source: :mcp,
        submitters_order: @template.preferences['submitters_order'].presence || 'random',
        submissions_attrs: { submitters: },
        params: { 'send_email' => true, 'submitters' => submitters }
      )

      return render_tool_error('No valid submitters provided') if submissions.blank?

      WebhookUrls.enqueue_events(submissions, 'submission.created')

      Submissions.send_signature_requests(submissions)

      SearchEntries.enqueue_reindex(submissions)

      submission = submissions.first

      render_tool_result(id: submission.id, status: 'pending')
    rescue Submissions::CreateFromSubmitters::BaseError => e
      render_tool_error(e.message)
    end
    # rubocop:enable Metrics
  end
end
