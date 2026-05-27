# Turbo is built to work with native navigation principles and present those alongside what's required for the web. When you
# have Hotwire Native clients running (see the Hotwire Native iOS and Hotwire Native Android projects for details),
# you can respond to native requests with three dedicated responses: <tt>recede</tt>, <tt>resume</tt>, <tt>refresh</tt>.
#
# Hotwire Native Android and Hotwire Native iOS handle these actions automatically.
module Turbo::Native::Navigation
  extend ActiveSupport::Concern

  included do
    helper_method :hotwire_native_app?, :turbo_native_app?
  end

  # Hotwire Native applications are identified by having the string "Hotwire Native" as part of their user agent.
  # Legacy Turbo Native applications use the "Turbo Native" string.
  def hotwire_native_app?
    request.user_agent.to_s.match?(/(Turbo|Hotwire) Native/)
  end

  alias_method :turbo_native_app?, :hotwire_native_app?

  # Tell the Turbo Native app to dismiss a modal (if presented) or pop a screen off of the navigation stack. Otherwise redirect to the given URL if Turbo Native is not present.
  def recede_or_redirect_to(url, **options)
    turbo_native_action_or_redirect url, :recede, :to, options
  end

  # Tell the Turbo Native app to ignore this navigation, otherwise redirect to the given URL if Turbo Native is not present.
  def resume_or_redirect_to(url, **options)
    turbo_native_action_or_redirect url, :resume, :to, options
  end

  # Tell the Turbo Native app to refresh the current screen, otherwise redirect to the given URL if Turbo Native is not present.
  def refresh_or_redirect_to(url, **options)
    turbo_native_action_or_redirect url, :refresh, :to, options
  end

  # Same as <tt>recede_or_redirect_to</tt> but redirects to the previous page or provided fallback location if the Turbo Native app is not present.
  def recede_or_redirect_back_or_to(url, **options)
    turbo_native_action_or_redirect url, :recede, :back, options
  end

  # Same as <tt>resume_or_redirect_to</tt> but redirects to the previous page or provided fallback location if the Turbo Native app is not present.
  def resume_or_redirect_back_or_to(url, **options)
    turbo_native_action_or_redirect url, :resume, :back, options
  end

  # Same as <tt>refresh_or_redirect_to</tt> but redirects to the previous page or provided fallback location if the Turbo Native app is not present.
  def refresh_or_redirect_back_or_to(url, **options)
    turbo_native_action_or_redirect url, :refresh, :back, options
  end
  
  private

  # :nodoc:
  def turbo_native_action_or_redirect(url, action, redirect_type, options = {})
    native_params = options.delete(:native_params) || {}

    if turbo_native_app?
      redirect_to send("turbo_#{action}_historical_location_url", notice: options[:notice], **native_params)
    elsif redirect_type == :back
      redirect_back fallback_location: url, **options
    else
      redirect_to url, options
    end
  end
end
