# frozen_string_literal: true

class Pagy
  protected

  # Label for any page. Allow the customization of the output
  def page_label(page, **options)
    return page.to_s unless calendar?

    options[:format] ||= @options[:format]
    localize(starting_time_for(page.to_i), **options)  # page could be a string
  end

  # Return a performance optimized lambda to generate the anchor tag
  # Benchmarked on a 20 link nav: it is ~22x faster and uses ~18x less memory than rails' link_to
  def a_lambda(anchor_string: @options[:anchor_string], **)
    left, right = %(<a href="#{compose_page_url(PAGE_TOKEN, **)}"#{
                    %( #{anchor_string}) if anchor_string}).split(PAGE_TOKEN, 2)

    lambda do |page, text = page_label(page), classes: nil, aria_label: nil|
      title = if calendar? && (counts = @options[:counts])
                count    = counts[page - 1]
                classes  = classes ? "#{classes} empty-page" : 'empty-page' if count.zero?
                info_key = count.zero? ? 'pagy.info_tag.no_items' : 'pagy.info_tag.single_page'
                %( title="#{I18n.translate(info_key, item_name: I18n.translate('pagy.item_name', count:), count:)}")
              end

      rel = case page
            when @previous then %( rel="prev")
            when @next     then %( rel="next")
            end

      %(#{left}#{page}#{right}#{title}#{
        %( class="#{classes}") if classes}#{rel}#{%( aria-label="#{aria_label}") if aria_label}>#{text}</a>)
    end
  end
end
