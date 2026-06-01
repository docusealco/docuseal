module Vips
  # What directory layout and metadata standard to use.
  #
  # *   `:dz` use DeepZoom directory layout
  # *   `:zoomify` use Zoomify directory layout
  # *   `:google` use Google maps directory layout
  # *   `:iiif` use IIIF v2 directory layout
  # *   `:iiif3` use IIIF v3 directory layout

  class ForeignDzLayout < Symbol
  end
end
