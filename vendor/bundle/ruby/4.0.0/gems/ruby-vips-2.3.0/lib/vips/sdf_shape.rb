module Vips
  # The SDF to generate, see {Image.sdf}.
  #
  # *   `:circle` a circle at @a, radius @r
  # *   `:box` a box from @a to @b
  # *   `:rounded_box` a box with rounded @corners from @a to @b
  # *   `:line` a line from @a to @b

  class SdfShape < Symbol
  end
end
