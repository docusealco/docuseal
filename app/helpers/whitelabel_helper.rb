# frozen_string_literal: true

# =============================================================================
# WhitelabelHelper — makes Whitelabel config available in all views
# =============================================================================
# Include this in ApplicationController to use `wl` in all ERB templates.
#
# Usage in views:
#   <%= wl.brand_name %>
#   <%= wl.logo_path %>
#   <%= wl.support_email %>
# =============================================================================

module WhitelabelHelper
  def wl
    Whitelabel
  end
end
