module Vips
  # The compression format to use inside a HEIF container
  #
  # *   `:hevc` x265
  # *   `:avc` x264
  # *   `:jpeg` jpeg
  # *   `:av1` aom

  class ForeignHeifCompression < Symbol
  end
end
