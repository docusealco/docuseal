module Vips
  # The container format to use
  #
  # *   `:fs` write tiles to the filesystem
  # *   `:zip` write tiles to a zip file
  # *   `:szi` write to a szi file

  class ForeignDzContainer < Symbol
  end
end
