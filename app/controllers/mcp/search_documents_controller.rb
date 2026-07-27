# frozen_string_literal: true

module Mcp
  class SearchDocumentsController < McpBaseController
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

    def call
      authorize!(:read, Submission)

      submissions = Submissions.search(current_user, Submission.accessible_by(current_ability).active,
                                       mcp_params['q'], search_template: true)

      limit = mcp_params.fetch('limit', 10).to_i
      limit = 10 if limit <= 0
      limit = [limit, 100].min
      submissions = submissions.preload(:submitters, :template)
                               .order(id: :desc)
                               .limit(limit)

      data = submissions.map do |submission|
        {
          id: submission.id,
          template_name: submission.template&.name,
          status: Submissions::SerializeForApi.build_status(submission, submission.submitters),
          submitters: submission.submitters.map do |s|
            { email: s.email, name: s.name, phone: s.phone, status: s.status }
          end,
          documents_url: submission_url(submission.id)
        }
      end

      render_tool_result(data)
    end
  end
end
