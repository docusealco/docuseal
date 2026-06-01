# frozen_string_literal: true

module Net
  class IMAP
    class Config
      # >>>
      #   *NOTE:* This module is an internal implementation detail, with no
      #   guarantee of backward compatibility.
      #
      # Adds a +type+ keyword parameter to +attr_accessor+, to enforce that
      # config attributes have valid types, for example: boolean, numeric,
      # enumeration, non-nullable, etc.
      module AttrTypeCoercion
        # :stopdoc: internal APIs only

        module Macros # :nodoc: internal API
          def attr_accessor(attr, type: nil)
            super(attr)
            AttrTypeCoercion.attr_accessor(attr, type: type)
          end

          module_function def Integer? = NilOrInteger
        end
        private_constant :Macros

        def self.included(mod)
          mod.extend Macros
        end
        private_class_method :included

        if defined?(Ractor.shareable_proc)
          def self.safe(&b)
            case obj = b.call
            when Proc
              Ractor.shareable_proc(&obj)
            else
              Ractor.make_shareable obj
            end
          end
        elsif defined?(Ractor.make_shareable)
          def self.safe(&b)
            obj = nil.instance_eval(&b).freeze
            Ractor.make_shareable obj
          end
        else
          def self.safe(&b) nil.instance_eval(&b).freeze end
        end
        private_class_method :safe

        Types = Hash.new do |h, type| type => Proc | nil; safe{type} end
        Types[:boolean] = Boolean = safe{-> {!!_1}}
        Types[Integer]  = safe{->{Integer(_1)}}

        def self.attr_accessor(attr, type: nil)
          type = Types[type] or return
          define_method :"#{attr}=" do |val| super type[val] end
          define_method :"#{attr}?" do send attr end if type == Boolean
        end

        NilOrInteger = safe{->val { Integer val unless val.nil? }}

        Enum = ->(*enum) {
          safe_enum = safe{enum}
          expected = -"one of #{safe_enum.map(&:inspect).join(", ")}"
          safe{->val {
            return val if safe_enum.include?(val)
            raise ArgumentError, "expected %s, got %p" % [expected, val]
          }}
        }

      end
    end
  end
end
