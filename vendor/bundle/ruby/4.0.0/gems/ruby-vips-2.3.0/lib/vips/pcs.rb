module Vips
  # Pick a Profile Connection Space for {Image#icc_import} and
  # {Image#icc_export}`.
  #
  # *   `:lab` use CIELAB D65 as the Profile Connection Space
  # *   `:xyz` use XYZ as the Profile Connection Space

  class PCS < Symbol
  end
end
