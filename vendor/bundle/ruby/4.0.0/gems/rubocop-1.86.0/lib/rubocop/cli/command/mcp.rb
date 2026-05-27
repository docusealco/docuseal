# frozen_string_literal: true

module RuboCop
  class CLI
    module Command
      # Start Model Context Protocol of RuboCop.
      # @api private
      class MCP < Base
        self.command_name = :mcp

        def run
          require_relative '../../mcp/server'

          RuboCop::MCP::Server.new(@config_store).start
        end
      end
    end
  end
end
