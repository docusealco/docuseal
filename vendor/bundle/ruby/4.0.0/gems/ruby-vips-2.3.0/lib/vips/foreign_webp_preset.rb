module Vips
  # Tune lossy encoder settings for different image types.
  #
  # *   `:default` default preset
  # *   `:picture` digital picture, like portrait, inner shot
  # *   `:photo` outdoor photograph, with natural lighting
  # *   `:drawing` hand or line drawing, with high-contrast details
  # *   `:icon` small-sized colorful images
  # *   `:text` text-like

  class ForeignWebpPreset < Symbol
  end
end
