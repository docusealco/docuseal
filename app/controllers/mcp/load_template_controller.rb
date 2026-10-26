# frozen_string_literal: true

module Mcp
  class LoadTemplateController < McpBaseController
    SCHEMA = {
      name: 'load_template',
      title: 'Load Template',
      description: 'Load a template with its fields. Each field includes name, type, and the signing role name.',
      inputSchema: {
        type: 'object',
        properties: {
          template_id: {
            type: 'integer',
            description: 'Template identifier'
          }
        },
        required: %w[template_id]
      },
      annotations: {
        readOnlyHint: true,
        destructiveHint: false,
        idempotentHint: true,
        openWorldHint: false
      }
    }.freeze

    def call
      @template = Template.accessible_by(current_ability).find(mcp_params['template_id'])

      authorize!(:read, @template)

      submitters_index = @template.submitters.index_by { |s| s['uuid'] }

      roles = @template.submitters.pluck('name')

      fields = @template.fields.filter_map do |field|
        next if field['name'].blank?

        {
          name: field['name'],
          type: field['type'],
          role: submitters_index[field['submitter_uuid']]&.dig('name')
        }
      end

      render_tool_result(
        id: @template.id,
        name: @template.name,
        roles: roles,
        fields: fields
      )
    end
  end
end
