# frozen_string_literal: true

module Mcp
  module HandleRequest
    TOOLS = [
      Mcp::Tools::SearchTemplates,
      Mcp::Tools::CreateTemplate,
      Mcp::Tools::SendDocuments,
      Mcp::Tools::SearchDocuments
    ].freeze

    TOOLS_SCHEMA = TOOLS.map { |t| t::SCHEMA }

    TOOLS_INDEX = TOOLS.index_by { |t| t::SCHEMA[:name] }

    module_function

    # rubocop:disable Metrics/MethodLength
    def call(body, current_user, current_ability)
      case body['method']
      when 'initialize'
        {
          jsonrpc: '2.0',
          id: body['id'],
          result: {
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
          }
        }
      when 'notifications/initialized'
        nil
      when 'ping'
        { jsonrpc: '2.0', id: body['id'], result: {} }
      when 'tools/list'
        { jsonrpc: '2.0', id: body['id'], result: { tools: TOOLS_SCHEMA } }
      when 'tools/call'
        tool = TOOLS_INDEX[body.dig('params', 'name')]

        raise "Unknown tool: #{body.dig('params', 'name')}" unless tool

        result = tool.call(body.dig('params', 'arguments') || {}, current_user, current_ability)

        { jsonrpc: '2.0', id: body['id'], result: }
      else
        {
          jsonrpc: '2.0',
          id: body['id'],
          error: {
            code: -32_601,
            message: "Method not found: #{body['method']}"
          }
        }
      end
    end
    # rubocop:enable Metrics/MethodLength
  end
end
