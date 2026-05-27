# frozen_string_literal: true

module RuboCop
  module Cop
    module Gemspec
      # Checks that `RUBY_VERSION` and `Ruby::VERSION` constants are not used in gemspec.
      # Using `RUBY_VERSION` and `Ruby::VERSION` are dangerous because value of the
      # constant is determined by `rake release`.
      # It's possible to have dependency based on ruby version used
      # to execute `rake release` and not user's ruby version.
      #
      # @example
      #
      #   # bad
      #   Gem::Specification.new do |spec|
      #     if RUBY_VERSION >= '3.0'
      #       spec.add_dependency 'gem_a'
      #     else
      #       spec.add_dependency 'gem_b'
      #     end
      #   end
      #
      #   # good
      #   Gem::Specification.new do |spec|
      #     spec.add_dependency 'gem_a'
      #   end
      #
      class RubyVersionGlobalsUsage < Base
        include GemspecHelp

        MSG = 'Do not use `%<ruby_version>s` in gemspec file.'

        # @!method ruby_version?(node)
        def_node_matcher :ruby_version?, <<~PATTERN
          {
            (const {cbase nil?} :RUBY_VERSION)
            (const (const {cbase nil?} :Ruby) :VERSION)
          }
        PATTERN

        def on_const(node)
          return unless gem_spec_with_ruby_version?(node)

          add_offense(node, message: format(MSG, ruby_version: node.source))
        end

        private

        def gem_spec_with_ruby_version?(node)
          gem_specification(processed_source.ast) && ruby_version?(node)
        end
      end
    end
  end
end
