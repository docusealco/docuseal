# frozen_string_literal: true

module Mcp
  module Tools
    module LoadTemplate
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

      module_function

      def call(arguments, _current_user, current_ability)
        template = Template.accessible_by(current_ability).find_by(id: arguments['template_id'])

        return { content: [{ type: 'text', text: 'Template not found' }], isError: true } unless template

        current_ability.authorize!(:read, template)

        submitters_index = template.submitters.index_by { |s| s['uuid'] }

        roles = template.submitters.pluck('name')

        fields = template.fields.filter_map do |field|
          next if field['name'].blank?

          {
            name: field['name'],
            type: field['type'],
            role: submitters_index[field['submitter_uuid']]&.dig('name')
          }
        end

        {
          content: [
            {
              type: 'text',
              text: {
                id: template.id,
                name: template.name,
                roles: roles,
                fields: fields
              }.to_json
            }
          ]
        }
      end
    end
  end
end
