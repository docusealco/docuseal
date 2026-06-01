# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for usage of `Module` methods returning arrays that can be replaced
      # with equivalent predicates.
      #
      # Calling a method returning an array then checking if an element is inside
      # it is much slower than using an equivalent predicate method. For example,
      # `instance_methods.include?` will return an array of all public and protected
      # instance methods in the module, then check if a given method is inside that
      # array, while `method_defined?` will do direct method lookup, which is much
      # faster and consumes less memory.
      #
      # @example
      #   # bad
      #   Array.instance_methods.include?(:size)
      #   Array.instance_methods.member?(:size)
      #   Array.instance_methods(true).include?(:size)
      #
      #   Array.instance_methods(false).include?(:find)
      #
      #   # good
      #   Array.method_defined?(:size)
      #
      #   Array.method_defined?(:find, false)
      #
      #   # bad
      #   Array.class_variables.include?(:foo)
      #   Array.constants.include?(:foo)
      #   Array.private_instance_methods.include?(:foo)
      #   Array.protected_instance_methods.include?(:foo)
      #   Array.public_instance_methods.include?(:foo)
      #   Array.included_modules.include?(:foo)
      #
      #   # good
      #   Array.class_variable_defined?(:foo)
      #   Array.const_defined?(:foo)
      #   Array.private_method_defined?(:foo)
      #   Array.protected_method_defined?(:foo)
      #   Array.public_method_defined?(:foo)
      #   Array.include?(:foo)
      #
      # @example AllowedMethods: [included_modules]
      #
      #   # good
      #   Array.included_modules.include?(:foo)
      #
      class ModuleMemberExistenceCheck < Base
        include AllowedMethods
        extend AutoCorrector

        MSG = 'Use `%<replacement>s` instead.'

        # @!method module_member_inclusion?(node)
        def_node_matcher :module_member_inclusion?, <<~PATTERN
          (call
            {(call _ %METHODS_WITH_INHERIT_PARAM _?) (call _ %METHODS_WITHOUT_INHERIT_PARAM)}
            {:include? :member?}
            _)
        PATTERN

        METHOD_REPLACEMENTS = {
          class_variables: :class_variable_defined?,
          constants: :const_defined?,
          included_modules: :include?,
          instance_methods: :method_defined?,
          private_instance_methods: :private_method_defined?,
          protected_instance_methods: :protected_method_defined?,
          public_instance_methods: :public_method_defined?
        }.freeze

        METHODS_WITHOUT_INHERIT_PARAM = Set[:class_variables, :included_modules].freeze
        METHODS_WITH_INHERIT_PARAM =
          (METHOD_REPLACEMENTS.keys.to_set - METHODS_WITHOUT_INHERIT_PARAM).freeze

        RESTRICT_ON_SEND = METHOD_REPLACEMENTS.keys.freeze

        def on_send(node)
          return unless (parent = node.parent)
          return unless module_member_inclusion?(parent)
          return unless simple_method_argument?(node) && simple_method_argument?(parent)
          return if allowed_method?(node.method_name)

          offense_range = node.location.selector.join(parent.source_range.end)
          replacement = replacement_for(node, parent)

          add_offense(offense_range, message: format(MSG, replacement: replacement)) do |corrector|
            corrector.replace(offense_range, replacement)
          end
        end
        alias on_csend on_send

        private

        def replacement_for(node, parent)
          replacement_method = METHOD_REPLACEMENTS.fetch(node.method_name)
          without_inherit_param = METHODS_WITHOUT_INHERIT_PARAM.include?(node.method_name)

          if without_inherit_param || node.first_argument.nil? || node.first_argument.true_type?
            "#{replacement_method}(#{parent.first_argument.source})"
          else
            "#{replacement_method}(#{parent.first_argument.source}, #{node.first_argument.source})"
          end
        end

        def simple_method_argument?(node)
          return false if node.splat_argument? || node.block_argument?
          return false if node.first_argument&.hash_type?

          true
        end
      end
    end
  end
end
