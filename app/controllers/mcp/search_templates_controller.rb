# frozen_string_literal: true

module Mcp
  class SearchTemplatesController < McpBaseController
    SCHEMA = {
      name: 'search_templates',
      title: 'Search Templates',
      description: 'Search document templates by name',
      inputSchema: {
        type: 'object',
        properties: {
          q: {
            type: 'string',
            description: 'Search query to filter templates by name'
          },
          limit: {
            type: 'integer',
            description: 'The number of templates to return (default 10)'
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
      authorize!(:read, Template)

      templates = Templates.search(current_user, Template.accessible_by(current_ability).active, mcp_params['q'])

      limit = mcp_params.fetch('limit', 10).to_i
      limit = 10 if limit <= 0
      limit = [limit, 100].min
      templates = templates.order(id: :desc).limit(limit)

      render_tool_result(templates.map { |t| { id: t.id, name: t.name } })
    end
  end
end
