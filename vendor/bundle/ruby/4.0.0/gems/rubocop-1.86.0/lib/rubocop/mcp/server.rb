# frozen_string_literal: true

begin
  require 'mcp'

  required_mcp_version = '0.6.0'

  if Gem::Version.new(required_mcp_version) > Gem::Version.new(MCP::VERSION)
    # While `mcp` is not a runtime dependency, users may have an outdated version installed.
    warn <<~MESSAGE
      Error: `mcp` gem version #{MCP::VERSION} was loaded, but `rubocop --mcp` requires #{required_mcp_version}.
      - If you're using Bundler and don't yet have `gem 'mcp'` as a dependency, add it now.
      - If you're using Bundler and already have `gem 'mcp'` as a dependency, update it to the most recent version.
      - If you don't use Bundler, run `gem update mcp`.
    MESSAGE
    exit!
  end
rescue LoadError => e
  raise unless e.path == 'mcp'

  warn <<~MESSAGE
    Error: Unable to load `mcp` gem. Add `gem 'mcp', '~> 0.6'` to your Gemfile, or run `gem install mcp`.
  MESSAGE

  exit!
end

require_relative '../lsp'
require_relative '../lsp/runtime'

module RuboCop
  module MCP
    # RuboCop MCP Server.
    # @api private
    class Server
      def initialize(config_store)
        @config_store = config_store
        @runtime = RuboCop::LSP::Runtime.new(@config_store)
        @options = {}
      end

      def start
        # No `protocol_version` is specified because draft feature by default can be used.
        server = ::MCP::Server.new(
          name: 'rubocop_mcp_server',
          version: RuboCop::Version::STRING,
          tools: [inspection_tool, autocorrection_tool]
        )

        ::MCP::Server::Transports::StdioTransport.new(server).open
      end

      private

      def inspection_tool
        build_tool(
          name: 'rubocop_inspection',
          description: 'Inspect Ruby code for offenses. ' \
                       'Provide `source_code` to check inline code or `path` to check files.',
          title: "RuboCop's inspection",
          destructive_hint: false,
          idempotent_hint: true,
          read_only_hint: true,
          safety_required: false
        ) do |path, source_code|
          run_inspection(path, source_code)
        end
      end

      def autocorrection_tool
        build_tool(
          name: 'rubocop_autocorrection',
          description: 'Autocorrect RuboCop offenses in Ruby code. ' \
                       'Provide `source_code` to correct inline code or `path` to correct files. ' \
                       'Set `safety` to false to include unsafe corrections.',
          title: "RuboCop's autocorrection",
          destructive_hint: true,
          idempotent_hint: false,
          read_only_hint: false,
          safety_required: true
        ) do |path, source_code, safety|
          run_autocorrection(path, source_code, safety)
        end
      end

      def run_inspection(path, source_code)
        if source_code
          offenses = @runtime.offenses(path || 'example.rb', source_code, source_code.encoding)
          offenses.to_json
        else
          process_files(path, filter_empty: true) do |file, source|
            offenses = @runtime.offenses(file, source, source.encoding)

            { path: PathUtil.relative_path(file), offenses: offenses }
          end
        end
      end

      def run_autocorrection(path, source_code, safety)
        command = safety ? 'rubocop.formatAutocorrects' : 'rubocop.formatAutocorrectsAll'

        if source_code
          @runtime.format(path || 'example.rb', source_code, command: command).tap do |corrected|
            write_file(path, corrected) if path
          end
        else
          process_files(path) do |file, source|
            @runtime.format(file, source, command: command).then do |corrected|
              write_file(file, corrected)

              { path: PathUtil.relative_path(file), corrected: source != corrected }
            end
          end
        end
      end

      def process_files(path, filter_empty: false)
        target_finder = RuboCop::TargetFinder.new(@config_store, @options)
        target_files = target_finder.find(path ? [path] : [], :only_recognized_file_types)
        all_files = target_files.map { |file| yield(file, read_file(file)) }
        files = filter_empty ? all_files.reject { |f| f[:offenses]&.empty? } : all_files

        { files: files, summary: build_summary(target_files, all_files) }.to_json
      end

      def read_file(file)
        config = @config_store.for_file(file)
        RuboCop::ProcessedSource.from_file(
          file, config.target_ruby_version, parser_engine: config.parser_engine
        ).raw_source
      rescue Errno::ENOENT
        raise RuboCop::Error, "No such file or directory: #{file}"
      end

      def write_file(file, content)
        File.write(file, content)
      rescue Errno::EACCES
        raise RuboCop::Error, "Permission denied: #{file}"
      rescue Errno::ENOSPC
        raise RuboCop::Error, "No space left on device: #{file}"
      rescue Errno::EROFS
        raise RuboCop::Error, "Read-only file system: #{file}"
      end

      # NOTE: It is useful for RuboCop's result summary to be shown in the LLM's responses
      # during interactions, so the summary is returned in a form that is easy for the LLM
      # to reason about. Since LLM execution is non-deterministic, it is also sensible to
      # compute the summary deterministically at this stage.
      def build_summary(target_files, files)
        summary = { target_file_count: target_files.count }
        if files.first&.key?(:offenses)
          summary[:offense_count] = files.sum { |f| f[:offenses].size }
        else
          summary[:corrected_file_count] = files.count { |f| f[:corrected] }
        end
        summary
      end

      # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists
      def build_tool(
        name:, description:,
        title:, destructive_hint:, idempotent_hint:, read_only_hint:, safety_required:
      )
        if safety_required
          safety_property = { safety: { type: 'boolean' } }
          required = ['safety']
        else
          safety_property = {}
          required = nil
        end

        ::MCP::Tool.define(
          name: name,
          description: description,
          input_schema: {
            properties: {
              path: { type: 'string' },
              source_code: { type: 'string' }
            }.merge(safety_property),
            required: required
          }.compact,
          annotations: {
            title: title,
            destructive_hint: destructive_hint,
            idempotent_hint: idempotent_hint,
            open_world_hint: false,
            read_only_hint: read_only_hint
          }
        ) do |path: nil, source_code: nil, safety: true|
          result = yield(path, source_code, safety)

          ::MCP::Tool::Response.new([{ type: 'text', text: result }])
        end
      end
      # rubocop:enable Metrics/MethodLength, Metrics/ParameterLists
    end
  end
end
