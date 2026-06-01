# frozen_string_literal: true

class Pagy
  SERIES_SLOTS = 7

  protected

  # Return the array of page numbers and :gap e.g. [1, :gap, 8, "9", 10, :gap, 36]
  def series(slots: @options[:slots] || SERIES_SLOTS, compact: @options[:compact], **)
    raise OptionError.new(self, :slots, 'to be an Integer >= 0', slots) unless slots.is_a?(Integer) && slots >= 0
    return [] if slots.zero?

    [].tap do |series|
      if slots >= @last
        series.push(*1..@last)
      else
        half  = (slots - 1) / 2                       # the left half might be 1 page shorter when the slots are even
        start = if @page <= half                      # @page in the first half
                  1
                elsif @page > (@last - slots + half)  # @page in the last half
                  @last - slots + 1
                else                                  # @page in the middle
                  @page - half
                end
        series.push(*(start...(start + slots)))
        unless compact || slots < SERIES_SLOTS        # Set first, last and :gap when needed
          series[0]  = 1
          series[1]  = :gap unless series[1]  == 2
          series[-2] = :gap unless series[-2] == @last - 1
          series[-1] = @last
        end
      end
      current = series.index(@page)
      series[current] = @page.to_s if current
    end
  end
end
