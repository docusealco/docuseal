# frozen_string_literal: true

class Pagy
  module NumericHelpers
    # Instances with count return "Displaying items 41-60 of 324 in total" or "Displaying Products 41-60 of 324 in total"
    # Instances with no count return only page info: "Page 3 of 100"
    def info_tag(id: nil, item_name: nil)
      i18n_key  = if @count.nil?
                    'pagy.info_tag.no_count'
                  elsif @count.zero?
                    'pagy.info_tag.no_items'
                  elsif @in == @count
                    'pagy.info_tag.single_page'
                  else
                    'pagy.info_tag.multiple_pages'
                  end

      info_data = if @count.nil?
                    { page: @page, pages: @last }
                  else
                    { item_name: item_name || I18n.translate('pagy.item_name', count: @count),
                      count:     @count,
                      from:      @from,
                      to:        @to }
                  end

      %(<span#{%( id="#{id}") if id} class="pagy info">#{I18n.translate(i18n_key, **info_data)}</span>)
    end
  end
end
