module Vips
  # The rendering intent.
  #
  # * `:perceptual` perceptual rendering intent
  # * `:relative` relative colorimetric rendering intent
  # * `:saturation` saturation rendering intent
  # * `:absolute` absolute colorimetric rendering intent
  # * `:auto` the rendering intent that the profile suggests

  class Intent < Symbol
  end
end
