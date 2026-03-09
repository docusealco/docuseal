# frozen_string_literal: true

module Mcp
  module Tools
    module SearchDocuments
      SCHEMA = {
        name: 'search_documents',
        title: 'Search Documents',
        description: 'Search signed or pending documents by submitter name, email, phone, or template name',
        inputSchema: {
          type: 'object',
          properties: {
            q: {
              type: 'string',
              description: 'Search by submitter name, email, phone, or template name'
            },
            limit: {
              type: 'integer',
              description: 'The number of results to return (default 10)'
            }
          },
          required: %w[q]
        },
        annotations: {
          readOnlyHint: true,
          destructiveHint: false,
          idempotentHint: true,
          openWorldHint: false
        }
      }.freeze

      module_function

      def call(arguments, current_user, current_ability)
        submissions = Submissions.search(current_user, Submission.accessible_by(current_ability).active,
                                         arguments['q'], search_template: true)

        limit = arguments.fetch('limit', 10).to_i
        limit = 10 if limit <= 0
        limit = [limit, 100].min
        submissions = submissions.preload(:submitters, :template)
                                 .order(id: :desc)
                                 .limit(limit)

        data = submissions.map do |submission|
          url = Rails.application.routes.url_helpers.submission_url(
            submission.id, **Docuseal.default_url_options
          )

          {
            id: submission.id,
            template_name: submission.template&.name,
            status: Submissions::SerializeForApi.build_status(submission, submission.submitters),
            submitters: submission.submitters.map do |s|
              { email: s.email, name: s.name, phone: s.phone, status: s.status }
            end,
            documents_url: url
          }
        end

        { content: [{ type: 'text', text: data.to_json }] }
      end
    end
  end
end
