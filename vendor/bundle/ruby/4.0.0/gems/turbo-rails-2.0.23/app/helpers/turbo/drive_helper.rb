# Helpers to configure Turbo Drive via meta directives. They come in two
# variants:
#
# The recommended option is to include +yield :head+ in the +<head>+ section
# of the layout. Then you can use the helpers in any view.
#
# ==== Example
#
#   # app/views/application.html.erb
#   <html><head><%= yield :head %></head><body><%= yield %></html>
#
#   # app/views/trays/index.html.erb
#   <% turbo_exempts_page_from_cache %>
#   <p>Page that shouldn't be cached by Turbo</p>
#
# Alternatively, you can use the +_tag+ variant of the helpers to only get the
# HTML for the meta directive.
module Turbo::DriveHelper
  # Pages that are more likely than not to be a cache miss can skip turbo cache to avoid visual jitter.
  # Cannot be used along with +turbo_exempts_page_from_preview+.
  def turbo_exempts_page_from_cache
    provide :head, turbo_exempts_page_from_cache_tag
  end

  # See +turbo_exempts_page_from_cache+.
  def turbo_exempts_page_from_cache_tag
    tag.meta(name: "turbo-cache-control", content: "no-cache")
  end

  # Specify that a cached version of the page should not be shown as a preview during an application visit.
  # Cannot be used along with +turbo_exempts_page_from_cache+.
  def turbo_exempts_page_from_preview
    provide :head, turbo_exempts_page_from_preview_tag
  end

  # See +turbo_exempts_page_from_preview+.
  def turbo_exempts_page_from_preview_tag
    tag.meta(name: "turbo-cache-control", content: "no-preview")
  end

  # Force the page, when loaded by Turbo, to be cause a full page reload.
  def turbo_page_requires_reload
    provide :head, turbo_page_requires_reload_tag
  end

  # See +turbo_page_requires_reload+.
  def turbo_page_requires_reload_tag
    tag.meta(name: "turbo-visit-control", content: "reload")
  end

  # Configure how to handle page refreshes. A page refresh happens when
  # Turbo loads the current page again with a *replace* visit:
  #
  # ==== Parameters:
  #
  # * <tt>method</tt> - Method to update the +<body>+ of the page
  #   during a page refresh. It can be one of:
  #   * +replace:+: Replaces the existing +<body>+ with the new one. This is the
  #   default behavior.
  #   * +morph:+: Morphs the existing +<body>+ into the new one.
  #
  # * <tt>scroll</tt> - Controls the scroll behavior when a page refresh happens. It
  #   can be one of:
  #   * +reset:+: Resets scroll to the top, left corner. This is the default.
  #   * +preserve:+: Keeps the scroll.
  #
  # ==== Example Usage:
  #
  #   turbo_refreshes_with(method: :morph, scroll: :preserve)
  def turbo_refreshes_with(method: :replace, scroll: :reset)
    provide :head, turbo_refresh_method_tag(method)
    provide :head, turbo_refresh_scroll_tag(scroll)
  end

  # Configure method to perform page refreshes. See +turbo_refreshes_with+.
  def turbo_refresh_method_tag(method = :replace)
    raise ArgumentError, "Invalid refresh option '#{method}'" unless method.to_sym.in?(%i[ replace morph ])
    tag.meta(name: "turbo-refresh-method", content: method)
  end

  # Configure scroll strategy for page refreshes. See +turbo_refreshes_with+.
  def turbo_refresh_scroll_tag(scroll = :reset)
    raise ArgumentError, "Invalid scroll option '#{scroll}'" unless scroll.to_sym.in?(%i[ reset preserve ])
    tag.meta(name: "turbo-refresh-scroll", content: scroll)
  end
end

