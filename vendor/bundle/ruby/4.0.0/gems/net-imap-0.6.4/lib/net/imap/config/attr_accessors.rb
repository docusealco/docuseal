# frozen_string_literal: true

require "forwardable"

module Net
  class IMAP
    class Config
      # >>>
      #   *NOTE:* This module is an internal implementation detail, with no
      #   guarantee of backward compatibility.
      #
      # +attr_accessor+ values are stored in a struct rather than ivars, making
      # it simpler to ensure that all config objects share a single object
      # shape.  This also simplifies iteration over all defined attributes.
      module AttrAccessors
        module Macros # :nodoc: internal API
          def attr_accessor(name) AttrAccessors.attr_accessor(name) end
        end
        private_constant :Macros

        def self.included(mod)
          mod.extend Macros
        end
        private_class_method :included

        extend Forwardable

        def self.attr_accessor(name) # :nodoc: internal API
          name = name.to_sym
          raise ArgumentError, "already defined #{name}" if attributes.include?(name)
          attributes << name
          def_delegators :data, name, :"#{name}="
        end

        # An array of Config attribute names
        singleton_class.attr_reader :attributes
        @attributes = []

        def self.struct # :nodoc: internal API
          attributes.freeze
          Struct.new(*attributes)
        end

        def initialize # :notnew:
          super()
          @data = Config::Struct.new
        end

        # Freezes the internal attributes struct, in addition to +self+.
        def freeze
          data.freeze
          super
        end

        protected

        attr_reader :data # :nodoc: internal API

        private

        def initialize_clone(other)
          super
          @data = other.data.clone
        end

        def initialize_dup(other)
          super
          @data = other.data.dup
        end

      end
    end
  end
end
