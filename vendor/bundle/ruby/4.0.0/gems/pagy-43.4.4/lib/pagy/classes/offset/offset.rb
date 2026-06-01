# frozen_string_literal: true

require_relative '../../modules/abilities/shiftable'
require_relative '../../modules/abilities/rangeable'

class Pagy
  # Implements Offset Pagination
  class Offset < Pagy
    DEFAULT = { page: 1 }.freeze

    autoload :Countless, Pathname.new(__dir__).join('countless')
    autoload :Countish,  Pathname.new(__dir__).join('countish')

    include Rangeable
    include Shiftable
    include NumericHelpers

    def initialize(**)
      assign_options(**)
      assign_and_check(limit: 1, count: 0, page: 1)
      assign_last
      assign_offset

      unless in_range? { @page <= @last }
        assign_empty_page_variables
        return
      end

      @from = [@offset + 1, @count].min
      @to   = [@offset + @limit, @count].min
      @in   = [@to - @from + 1, @count].min

      assign_previous_and_next
    end

    attr_reader :offset, :count, :from, :to, :in, :previous, :next, :last
    alias pages last

    def records(collection)
      collection.offset(@offset).limit(@limit)
    end

    protected

    def offset? = true

    def assign_last
      @last = [(@count.to_f / @limit).ceil, 1].max
      @last = @options[:max_pages] if @options[:max_pages] && @last > @options[:max_pages]
    end

    def assign_offset
      @offset = (@limit * (@page - 1))
    end

    # Called by false in_range?
    def assign_empty_page_variables
      @in = @from = @to = 0     # options relative to the actual page
      @previous = @last         # @previous relative to the actual page
    end
  end
end
