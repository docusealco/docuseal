# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Enforces consistency by using the current HTTP status names.
      #
      # @example
      #   # bad
      #   render json: { error: "Invalid data" }, status: :unprocessable_entity
      #   head :payload_too_large
      #
      #   # good
      #   render json: { error: "Invalid data" }, status: :unprocessable_content
      #   head :content_too_large
      #
      class HttpStatusNameConsistency < Base
        extend AutoCorrector

        requires_gem 'rack', '>= 3.1.0'

        RESTRICT_ON_SEND = %i[render redirect_to head assert_response assert_redirected_to].freeze

        PREFERRED_STATUSES = {
          unprocessable_entity: :unprocessable_content,
          payload_too_large: :content_too_large
        }.freeze

        MSG = 'Prefer `:%<preferred>s` over `:%<current>s`.'

        def_node_matcher :status_method_call, <<~PATTERN
          {
            (send nil? {:render :redirect_to} _ $hash)
            (send nil? {:render :redirect_to} $hash)
            (send nil? {:head :assert_response} $_ ...)
            (send nil? :assert_redirected_to _ $hash ...)
            (send nil? :assert_redirected_to $hash ...)
          }
        PATTERN

        def_node_matcher :status_hash_value, <<~PATTERN
          (hash <(pair (sym :status) $_) ...>)
        PATTERN

        def on_send(node)
          status_method_call(node) do |status_node|
            if status_node.hash_type?
              # Handle hash arguments like { status: :unprocessable_entity }
              status_hash_value(status_node) do |status_value|
                check_status_name_consistency(status_value)
              end
            else
              # Handle positional arguments like head :unprocessable_entity
              check_status_name_consistency(status_node)
            end
          end
        end

        private

        def check_status_name_consistency(node)
          if node.sym_type? && PREFERRED_STATUSES.key?(node.value)
            current_status = node.value
            preferred_status = PREFERRED_STATUSES[current_status]

            message = format(MSG, current: current_status, preferred: preferred_status)

            add_offense(node, message: message) do |corrector|
              corrector.replace(node, ":#{preferred_status}")
            end
          else
            node.children.each do |child|
              check_status_name_consistency(child) if child.is_a?(Parser::AST::Node)
            end
          end
        end
      end
    end
  end
end
