# frozen_string_literal: true

class Pagy
  # Return the page url for any page
  def page_url(page, **)
    target = case page
             when :first          then nil
             when :current, :page then @page
             when :previous       then @previous
             when :next           then @next
             when :last           then @last
             else                      page
             end

    compose_page_url(target, **) if target || page == :first
  end
end
