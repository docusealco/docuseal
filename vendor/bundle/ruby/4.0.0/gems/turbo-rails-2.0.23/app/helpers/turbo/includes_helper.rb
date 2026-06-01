module Turbo::IncludesHelper
  # DEPRECATED: Just use <tt>javascript_include_tag "turbo", type: "module"</tt> directly if using Turbo alone, or
  # javascript_include_tag "turbo", type: "module-shim" if together with Stimulus and importmaps.
  def turbo_include_tags
    javascript_include_tag("turbo", type: "module")
  end
end
