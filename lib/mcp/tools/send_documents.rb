# frozen_string_literal: true

module Mcp
  module Tools
    module SendDocuments
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

      # rubocop:disable Metrics/MethodLength
      def call(arguments, current_user, current_ability)
        template = Template.accessible_by(current_ability).find_by(id: arguments['template_id'])

        return { content: [{ type: 'text', text: 'Template not found' }], isError: true } unless template

        current_ability.authorize!(:create, Submission.new(template:, account_id: current_user.account_id))

        return { content: [{ type: 'text', text: 'Template has no fields' }], isError: true } if template.fields.blank?

        submitters = (arguments['submitters'] || []).map do |s|
          s.slice('email', 'name', 'role', 'phone')
           .compact_blank
           .with_indifferent_access
        end

        submissions = Submissions.create_from_submitters(
          template:,
          user: current_user,
          source: :api,
          submitters_order: 'random',
          submissions_attrs: { submitters: submitters },
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
      rescue Submissions::CreateFromSubmitters::BaseError => e
        { content: [{ type: 'text', text: e.message }], isError: true }
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
