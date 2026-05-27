# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks unexpected overrides of the `Data` built-in methods
      # via `Data.define`.
      #
      # @example
      #   # bad
      #   Bad = Data.define(:members, :clone, :to_s)
      #   b = Bad.new(members: [], clone: true, to_s: 'bad')
      #   b.members #=> [] (overriding `Data#members`)
      #   b.clone #=> true (overriding `Object#clone`)
      #   b.to_s #=> "bad" (overriding `Data#to_s`)
      #
      #   # good
      #   Good = Data.define(:id, :name)
      #   g = Good.new(id: 1, name: "foo")
      #   g.members #=> [:id, :name]
      #   g.clone #=> #<data Good id=1, name="foo">
      #
      class DataDefineOverride < Base
        MSG = '`%<member_name>s` member overrides `Data#%<method_name>s` and it may be unexpected.'
        RESTRICT_ON_SEND = %i[define].freeze

        # This is based on `Data.define.instance_methods.sort` in Ruby 4.0.0.
        DATA_METHOD_NAMES = %i[
          ! != !~ <=> == === __id__ __send__ class clone deconstruct deconstruct_keys
          define_singleton_method display dup enum_for eql? equal? extend freeze frozen? hash
          inspect instance_eval instance_exec instance_of? instance_variable_defined?
          instance_variable_get instance_variable_set instance_variables is_a? itself kind_of?
          members method methods nil? object_id private_methods protected_methods
          public_method public_methods public_send remove_instance_variable respond_to? send
          singleton_class singleton_method singleton_methods tap then to_enum to_h to_s with
          yield_self
        ].freeze
        MEMBER_NAME_TYPES = %i[sym str].freeze

        # @!method data_define(node)
        def_node_matcher :data_define, <<~PATTERN
          (send
            (const {nil? cbase} :Data) :define ...)
        PATTERN

        def on_send(node)
          return unless data_define(node)

          node.arguments.each do |arg|
            next unless MEMBER_NAME_TYPES.include?(arg.type)

            member_name = arg.value

            next unless DATA_METHOD_NAMES.include?(member_name.to_sym)

            message = format(MSG, member_name: member_name.inspect, method_name: member_name.to_s)
            add_offense(arg, message: message)
          end
        end
      end
    end
  end
end
