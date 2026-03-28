# frozen_string_literal: true

module SilenceErrors
  def log_error(request, wrapper)
    return if wrapper.status_code == 404

    super
  end
end

ActionDispatch::DebugExceptions.prepend(SilenceErrors)
