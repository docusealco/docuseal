# Turbo frame requests are requests made from within a turbo frame with the intention of replacing the content of just
# that frame, not the whole page. They are automatically tagged as such by the Turbo Frame JavaScript, which adds a
# <tt>Turbo-Frame</tt> header to the request.
#
# When that header is detected by the controller, we substitute our own minimal layout in place of the
# application-supplied layout (since we're only working on an in-page frame, thus can skip the weight of the layout). We
# use a minimal layout, rather than avoid the layout entirely, so that it's still possible to render content into the
# <tt>head</tt>.
#
# Accordingly, we ensure that the etag for the page is changed, such that a cache for a minimal-layout request isn't
# served on a normal request and vice versa.
#
# This is merely a rendering optimization. Everything would still work just fine if we rendered everything including the
# full layout. Turbo Frames knows how to fish out the relevant frame regardless.
#
# The layout used is <tt>turbo_rails/frame.html.erb</tt>. If there's a need to customize this layout, an application can
# supply its own (such as <tt>app/views/layouts/turbo_rails/frame.html.erb</tt>) which will be used instead.
#
# This module is automatically included in <tt>ActionController::Base</tt>.
module Turbo::Frames::FrameRequest
  extend ActiveSupport::Concern

  included do
    layout -> { "turbo_rails/frame" if turbo_frame_request? }
    etag { :frame if turbo_frame_request? }

    helper_method :turbo_frame_request?, :turbo_frame_request_id
  end

  private
    def turbo_frame_request?
      turbo_frame_request_id.present?
    end

    def turbo_frame_request_id
      request.headers["Turbo-Frame"]
    end
end
