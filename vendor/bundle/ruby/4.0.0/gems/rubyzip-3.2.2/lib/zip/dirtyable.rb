# frozen_string_literal: true

module Zip
  module Dirtyable # :nodoc:all
    def initialize(dirty_on_create: true)
      @dirty = dirty_on_create
    end

    def dirty?
      @dirty
    end

    module ClassMethods # :nodoc:
      def mark_dirty(*symbols) # :nodoc:
        # Move the original method and call it after we've set the dirty flag.
        symbols.each do |symbol|
          orig_name = "orig_#{symbol}"
          alias_method orig_name, symbol

          define_method(symbol) do |param|
            @dirty = true
            send(orig_name, param)
          end
        end
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
