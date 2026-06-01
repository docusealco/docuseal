class Turbo::Native::NavigationController < ActionController::Base
  def recede
    render html: "Going back…"
  end

  def refresh
    render html: "Refreshing…"
  end

  def resume
    render html: "Staying put…"
  end
end
