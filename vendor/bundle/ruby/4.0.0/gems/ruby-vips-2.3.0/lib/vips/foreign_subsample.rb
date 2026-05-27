module Vips
  # Set subsampling mode.
  #
  # *   `:auto` prevent subsampling when quality >= 90
  # *   `:on` always perform subsampling
  # *   `:off` never perform subsampling

  class ForeignSubsample < Symbol
  end
end
