# frozen_string_literal: true

class Pagy
  # Add method supporting range checking, range error and rescue
  module Rangeable
    # Check if in range
    def in_range?
      return @in_range if defined?(@in_range)
      return true if (@in_range = yield)
      raise RangeError.new(self, :page, "in 1..#{@last}", @page) if @options[:raise_range_error]

      @in_range = false
    end
  end
end
