module Vips
  # A resizing kernel. One of these can be given to operations like
  # {Image#reduceh} or {Image#resize} to select the resizing kernel to use.
  #
  # At least these should be available:
  #
  # *   `:nearest` nearest-neighbour interpolation
  # *   `:linear` linear interpolation
  # *   `:cubic` cubic interpolation
  # *   `:mitchell` Mitchell interpolation
  # *   `:lanczos2` two-lobe Lanczos
  # *   `:lanczos3` three-lobe Lanczos
  # *   `:mks2013` convolve with Magic Kernel Sharp 2013
  # *   `:mks2021` convolve with Magic Kernel Sharp 2021
  #
  #  For example:
  #
  #  ```ruby
  #  im = im.resize 3, kernel: :lanczos2
  #  ```

  class Kernel < Symbol
  end
end
