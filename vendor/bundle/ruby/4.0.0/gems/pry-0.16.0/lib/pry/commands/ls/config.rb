# frozen_string_literal: true

require 'forwardable'

class Pry
  class Command
    class Ls < Pry::ClassCommand
      class Config
        extend Forwardable

        DEFAULT_OPTIONS = {
          heading_color: :bright_blue,
          public_method_color: :default,
          private_method_color: :blue,
          protected_method_color: :blue,
          method_missing_color: :bright_red,
          local_var_color: :yellow,
          pry_var_color: :default,            # e.g. _, pry_instance, _file_
          instance_var_color: :blue,          # e.g. @foo
          class_var_color: :bright_blue,      # e.g. @@foo
          global_var_color: :default,         # e.g. $CODERAY_DEBUG, $eventmachine_library
          builtin_global_color: :cyan,        # e.g. $stdin, $-w, $PID
          pseudo_global_color: :cyan,         # e.g. $~, $1..$9, $LAST_MATCH_INFO
          constant_color: :default,           # e.g. VERSION, ARGF
          class_constant_color: :blue,        # e.g. Object, Kernel
          exception_constant_color: :magenta, # e.g. Exception, RuntimeError
          unloaded_constant_color: :yellow,   # Constant still in .autoload? state
          separator: "  ",
          ceiling: [Object, Module, Class]
        }.freeze

        DEFAULT_OPTIONS.each_key do |key|
          define_method key do
            @config[key]
          end

          define_method "#{key}=" do |value|
            @config[key] = value
          end
        end

        def_delegators :@config, :[], :[]=, :each, :each_pair, :values, :keys, :to_a

        def initialize(config)
          @config = config
        end

        def self.default
          new(DEFAULT_OPTIONS.dup)
        end
      end
    end
  end
end
