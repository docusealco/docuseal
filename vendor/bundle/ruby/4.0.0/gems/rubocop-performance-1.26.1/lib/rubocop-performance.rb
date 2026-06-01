# frozen_string_literal: true

require 'rubocop'

require_relative 'rubocop/performance'
require_relative 'rubocop/performance/version'
require_relative 'rubocop/performance/plugin'
require_relative 'rubocop/cop/performance_cops'

autocorrect_incompatible_with_block_given_with_explicit_block = Module.new do
  def autocorrect_incompatible_with
    super.push(RuboCop::Cop::Performance::BlockGivenWithExplicitBlock)
  end
end

RuboCop::Cop::Lint::UnusedMethodArgument.singleton_class.prepend(
  autocorrect_incompatible_with_block_given_with_explicit_block
)

RuboCop::Cop::Naming::BlockForwarding.singleton_class.prepend(
  autocorrect_incompatible_with_block_given_with_explicit_block
)
