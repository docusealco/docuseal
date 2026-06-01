# frozen_string_literal: true

module ERBLint
  module Linters
    # Enforces the use of strict locals in Rails view partial templates.
    class StrictLocals < Linter
      include LinterRegistry

      STRICT_LOCALS_REGEX = /\s+locals:\s+\((.*)\)/

      def initialize(file_loader, config)
        super
      end

      def run(processed_source)
        return unless processed_source.filename.match?(%r{(\A|.*/)_[^/\s]*\.html\.erb\z})

        file_content = processed_source.file_content
        return if file_content.empty?

        strict_locals_node = processed_source.ast.descendants(:erb).find do |erb_node|
          indicator_node, _, code_node, _ = *erb_node

          indicator_node_str = indicator_node&.deconstruct&.last
          next unless indicator_node_str == "#"

          code_node_str = code_node&.deconstruct&.last

          code_node_str.match(STRICT_LOCALS_REGEX)
        end

        unless strict_locals_node
          add_offense(
            processed_source.to_source_range(0...processed_source.file_content.size),
            <<~EOF.chomp,
              Missing strict locals declaration.
              Add <%# locals: () %> at the top of the file to enforce strict locals.
            EOF
          )
        end
      end

      def autocorrect(_processed_source, offense)
        lambda do |corrector|
          corrector.insert_before(offense.source_range, "<%# locals: () %>\n")
        end
      end
    end
  end
end
