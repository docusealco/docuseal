module Vips
  # How many pyramid layers to create.
  #
  # *   `:onepixel` create layers down to 1x1 pixel
  # *   `:onetile` create layers down to 1x1 tile
  # *   `:one` only create a single layer

  class ForeignDzDepth < Symbol
  end
end
