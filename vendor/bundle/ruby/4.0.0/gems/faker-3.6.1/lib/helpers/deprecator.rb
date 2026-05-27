# frozen_string_literal: true

# Based on Rails ActiveSupport Deprecator
# https://github.com/rails/rails/blob/main/activesupport/lib/active_support/deprecation/constant_accessor.rb

# rubocop:disable Style/ClassVars
module Faker
  # Provides a way to rename generators, including their namespaces, with a deprecation cycle in which
  # both the old and new names work, but using the old one prints a deprecation message.
  #
  # Deprecator provides a deprecate_generator method to be used when
  # renaming a generator. For example, let's say we want to change the following Generator's
  # name to <tt>Faker::NewGenerator</tt>:
  #
  #   module Faker
  #     class Generator
  #       def self.generate
  #         "be kind"
  #       end
  #     end
  #   end
  #
  # To rename it, you need to do the update the name and declare the deprecation by
  # including the <tt>Deprecator</tt> module and using the deprecate_generator method:
  #
  #   module Faker
  #     class NewGenerator
  #       def self.generate
  #         "be kind"
  #       end
  #     end
  #
  #     include Deprecator
  #     deprecate_generator('DeprecatedGenerator', NewGenerator)
  #   end
  #
  # The first argument is a constant name (no colons) as a string. It is the name of
  # the constant you want to deprecate.
  #
  # The second argument is the constant path of the replacement (no colons) as a constant.
  #
  # For this to work, a +const_missing+ hook is installed. When users
  # reference the deprecated constant, the callback prints the
  # message and constantizes the replacement.
  #
  # With that in place, references to <tt>Faker::Deprecator</tt> still work, they
  # evaluate to <tt>Faker::NewGenerator</tt> now, and trigger a deprecation warning:
  #
  #   Faker::Generator.generate
  #   # DEPRECATION WARNING: Faker::Generator is deprecated. Use Faker::NewGenerator instead
  #   # "be kind"
  #
  # For testing the deprecations, we provide <tt>assert_deprecated</tt>
  # and <tt>assert_not_deprecated</tt> matchers.
  #
  # There's also a <tt>Faker::Deprecator.skip_warning</tt> helper to silence
  # the deprecation messages in the *test* output. Use it for generators that have lots of tests
  # to avoid too many noise when running the tests.
  module Deprecator
    def self.included(base)
      extension = Module.new do
        def const_missing(missing_const_name)
          if class_variable_defined?(:@@_deprecated_constants) && (replacement = class_variable_get(:@@_deprecated_constants)[missing_const_name.to_s])
            unless Faker::Deprecator.skip_warning?
              deprecated_message = "#{name}::#{replacement[:old_generator]} is deprecated."
              replacement_message = "Use #{replacement[:new_constant]} instead."
              $stdout.puts("DEPRECATION WARNING: #{deprecated_message} #{replacement_message}")
            end

            return replacement[:new_constant]
          end

          super
        end

        def deprecate_generator(old_generator_name, new_generator_constant)
          class_variable_set(:@@_deprecated_constants, {}) unless class_variable_defined?(:@@_deprecated_constants)
          class_variable_get(:@@_deprecated_constants)[old_generator_name] = {
            new_constant: new_generator_constant,
            old_generator: old_generator_name
          }
        end
      end

      base.singleton_class.prepend extension
    end

    # Silence deprecation warnings within the block.
    #
    #   Faker::Generator.generate
    #   # => DEPRECATION WARNING: Faker::Generator is deprecated. Use Faker::NewGenerator instead.
    #
    #   Faker::Deprecator.skip_warning do
    #     Faker::Generator.generate
    #   end
    #   # => nil
    def self.skip_warning
      original = Faker::Deprecator.skip
      Faker::Deprecator.skip = true
      yield
    ensure
      Faker::Deprecator.skip = original
    end

    def self.skip_warning?
      @skip == true
    end

    def self.skip
      @skip ||= false
    end

    def self.skip=(value)
      @skip = value
    end
  end
end
# rubocop:enable Style/ClassVars
