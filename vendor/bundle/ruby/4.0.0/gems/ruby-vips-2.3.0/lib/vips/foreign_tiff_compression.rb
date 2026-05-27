module Vips
  # The compression types supported by the tiff writer.
  #
  # *   `:none` no compression
  # *   `:jpeg` jpeg compression
  # *   `:deflate` deflate (zip) compression
  # *   `:packbits` packbits compression
  # *   `:ccittfax4` fax4 compression
  # *   `:lzw` LZW compression
  # *   `:webp` WEBP compression
  # *   `:zstd` ZSTD compression
  # *   `:jp2k` JP2K compression

  class ForeignTiffCompression < Symbol
  end
end
