module Vips
  # Savers can be given a set of metadata items to keep.
  #
  # *   `:none` remove all metadata
  # *   `:exif` keep EXIF metadata
  # *   `:xmp` keep XMP metadata
  # *   `:iptc` keep IPTC metadata
  # *   `:icc` keep ICC profiles
  # *   `:gainmap` keep the gainmap metadata
  # *   `:other` keep other metadata

  class ForeignKeep < Symbol
  end
end
