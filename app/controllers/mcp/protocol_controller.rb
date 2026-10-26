# frozen_string_literal: true

module Mcp
  class ProtocolController < McpBaseController
    skip_authorization_check

    def ok
      head :ok
    end

    def initialize_request
      render_result(
        protocolVersion: '2025-11-25',
        serverInfo: {
          name: 'DocuSeal',
          version: Docuseal.version.to_s
        },
        capabilities: {
          tools: {
            listChanged: false
          }
        }
      )
    end

    def initialized_notification
      head :accepted
    end

    def ping
      render_result({})
    end

    def tools_list
      render_result(tools: McpController::TOOLS)
    end

    def method_not_found
      render_error(-32_601, "Method not found: #{mcp_body['method']}", id: mcp_body['id'])
    end

    def tool_not_found
      render_error(-32_602, "Unknown tool: #{mcp_body.dig('params', 'name')}", id: mcp_body['id'])
    end

    def parse_error
      render_error(-32_700, 'Parse error', status: :bad_request)
    end
  end
end
