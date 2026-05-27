# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks unexpected overrides of the `Struct` built-in methods
      # via `Struct.new`.
      #
      # @example
      #   # bad
      #   Bad = Struct.new(:members, :clone, :count)
      #   b = Bad.new([], true, 1)
      #   b.members #=> [] (overriding `Struct#members`)
      #   b.clone #=> true (overriding `Object#clone`)
      #   b.count #=> 1 (overriding `Enumerable#count`)
      #
      #   # good
      #   Good = Struct.new(:id, :name)
      #   g = Good.new(1, "foo")
      #   g.members #=> [:id, :name]
      #   g.clone #=> #<struct Good id=1, name="foo">
      #   g.count #=> 2
      #
      class StructNewOverride < Base
        MSG = '`%<member_name>s` member overrides `Struct#%<method_name>s` ' \
              'and it may be unexpected.'
        RESTRICT_ON_SEND = %i[new].freeze

        # This is based on `Struct.instance_methods.sort` in Ruby 4.0.0.
        STRUCT_METHOD_NAMES = %i[
          ! != !~ <=> == === [] []= __id__ __send__ all? any? chain chunk chunk_while class clone
          collect collect_concat compact count cycle deconstruct deconstruct_keys
          define_singleton_method detect dig display drop drop_while dup each each_cons each_entry
          each_pair each_slice each_with_index each_with_object entries enum_for eql? equal? extend
          filter filter_map find find_all find_index first flat_map freeze frozen? grep grep_v
          group_by hash include? inject inspect instance_eval instance_exec instance_of?
          instance_variable_defined? instance_variable_get instance_variable_set instance_variables
          is_a? itself kind_of? lazy length map max max_by member? members method methods
          min min_by minmax minmax_by nil? none? object_id one? partition private_methods
          protected_methods public_method public_methods public_send reduce reject
          remove_instance_variable respond_to? reverse_each select send singleton_class
          singleton_method singleton_methods size slice_after slice_before slice_when sort sort_by
          sum take take_while tally tap then to_a to_enum to_h to_s to_set uniq values values_at
          yield_self zip
        ].freeze
        STRUCT_MEMBER_NAME_TYPES = %i[sym str].freeze

        # @!method struct_new(node)
        def_node_matcher :struct_new, <<~PATTERN
          (send
            (const {nil? cbase} :Struct) :new ...)
        PATTERN

        def on_send(node)
          return unless struct_new(node)

          node.arguments.each_with_index do |arg, index|
            # Ignore if the first argument is a class name
            next if index.zero? && arg.str_type?

            # Ignore if the argument is not a member name
            next unless STRUCT_MEMBER_NAME_TYPES.include?(arg.type)

            member_name = arg.value

            next unless STRUCT_METHOD_NAMES.include?(member_name.to_sym)

            message = format(MSG, member_name: member_name.inspect, method_name: member_name.to_s)
            add_offense(arg, message: message)
          end
        end
      end
    end
  end
end
