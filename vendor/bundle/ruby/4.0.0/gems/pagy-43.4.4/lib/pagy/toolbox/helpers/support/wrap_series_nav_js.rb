# frozen_string_literal: true

require_relative 'series'
require_relative 'nav_aria_label_attribute'
require_relative 'data_pagy_attribute'
require_relative 'a_lambda' # inherited use

# Relegate internal functions. Make overriding navs easier.
class Pagy
  private

  # Return the reverse sorted array of widths, series, and labels generated from the :steps hash
  # If :steps is false it will use the single {0 => @options[:slots]} length
  def sequels(steps: @options[:steps] || { 0 => @options[:slots] || SERIES_SLOTS }, **)
    raise OptionError.new(self, :steps, 'to define the 0 width', steps) unless steps.key?(0)

    widths, series = steps.sort.reverse.map { |width, slots| [width, series(slots:)] }.transpose
    [widths, series, page_labels(series)]
  end

  # Support for the Calendar API
  def page_labels(series)
    return unless calendar?

    series.map do |s|
      s.map { _1 == :gap ? :gap : page_label(_1) }
    end
  end

  # Build the nav_js tag, with the specific tokens for the style
  def wrap_series_nav_js(tokens, nav_classes, id: nil, aria_label: nil, **)
    sequels     = sequels(**)
    nav_classes = "pagy-rjs #{nav_classes}" if sequels[0].size > 1

    %(<nav#{%( id="#{id}") if id} class="#{nav_classes}" #{
      nav_aria_label_attribute(aria_label:)} #{
      data = [:snj, tokens.values, PAGE_TOKEN, sequels]
      data.push(@update) if keynav?
      data_pagy_attribute(*data)
      }></nav>)
  end
end
