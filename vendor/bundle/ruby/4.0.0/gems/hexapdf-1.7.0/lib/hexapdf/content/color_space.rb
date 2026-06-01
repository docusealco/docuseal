# -*- encoding: utf-8; frozen_string_literal: true -*-
#
#--
# This file is part of HexaPDF.
#
# HexaPDF - A Versatile PDF Creation and Manipulation Library For Ruby
# Copyright (C) 2014-2025 Thomas Leitner
#
# HexaPDF is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License version 3 as
# published by the Free Software Foundation with the addition of the
# following permission added to Section 15 as permitted in Section 7(a):
# FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
# THOMAS LEITNER, THOMAS LEITNER DISCLAIMS THE WARRANTY OF NON
# INFRINGEMENT OF THIRD PARTY RIGHTS.
#
# HexaPDF is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public
# License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with HexaPDF. If not, see <http://www.gnu.org/licenses/>.
#
# The interactive user interfaces in modified source and object code
# versions of HexaPDF must display Appropriate Legal Notices, as required
# under Section 5 of the GNU Affero General Public License version 3.
#
# In accordance with Section 7(b) of the GNU Affero General Public
# License, a covered work must retain the producer line in every PDF that
# is created or manipulated using HexaPDF.
#
# If the GNU Affero General Public License doesn't fit your need,
# commercial licenses are available at <https://gettalong.at/hexapdf/>.
#++

require 'hexapdf/error'
require 'hexapdf/content'
require 'hexapdf/configuration'
require 'hexapdf/serializer'

module HexaPDF
  module Content

    # This module contains the color space implementations.
    #
    # == General Information
    #
    # The PDF specification defines several color spaces. Probably the most used ones are the
    # device color spaces DeviceRGB, DeviceCMYK and DeviceGray. However, there are several others.
    # For example, patterns are also implemented via color spaces.
    #
    # HexaPDF provides implementations for the most common color spaces. Additional ones can
    # easily be added. After implementing one it just has to be registered on the global
    # configuration object under the 'color_space.map' key.
    #
    # Color space implementations are currently used so that different colors can be
    # distinguished and to provide better error handling.
    #
    #
    # == Color Space Implementations
    #
    # A color space implementation consists of two classes: one for the color space and one for
    # its colors.
    #
    # The class for the color space needs to respond to the following methods:
    #
    # #initialize(definition)::
    #   Creates the color space using the given array with the color space definition. The first
    #   item in the array is always the color space family, the other items are color space
    #   specific.
    #
    # #family::
    #   Returns the PDF name of the color space family this color space belongs to.
    #
    # #definition::
    #   Returns the color space definition as array or symbol.
    #
    # #default_color::
    #   Returns the default color for this color space.
    #
    # #color(*args)::
    #   Returns the color corresponding to the given arguments which may be normalized to conform to
    #   the PDF spec. The number and types of the arguments differ from one color space to another.
    #
    # #prenormalized_color(*args)::
    #   Returns the color corresponding to the given arguments without applying value normalization.
    #   The number and types of the arguments differ from one color space to another.
    #
    #   This method should be used when the arguments are already normalized (e.g. when loaded from
    #   a content stream).
    #
    # The class representing a color in the color space needs to respond to the following methods:
    #
    # #color_space::
    #   Returns the associated color space object.
    #
    # #components::
    #   Returns an array of components that uniquely identifies this color within the color space.
    #
    # See: PDF2.0 s8.6
    module ColorSpace

      # Mapping of color names (CSS Color Module Level 3 names - see
      # https://www.w3.org/TR/css-color-3/#svg-color - and HexaPDF design color names) to RGB and
      # gray values.
      #
      # Visual listing of all colors:
      #
      #   #>pdf-big
      #   canvas.font("Helvetica", size: 7.5)
      #   map = HexaPDF::Content::ColorSpace::COLOR_NAMES
      #   map.each_slice(43).each_with_index do |slice, col|
      #     x = 10 + col * 100
      #     slice.each_with_index do |(name, rgb), row|
      #       canvas.fill_color(rgb).rectangle(x, 380 - row * 9, 9, 9).fill
      #       canvas.fill_color("black").text(name, at: [x + 15, 380 - row * 9 + 2])
      #     end
      #   end
      COLOR_NAMES = {
        "aliceblue" => [240, 248, 255],
        "antiquewhite" => [250, 235, 215],
        "aqua" => [0, 255, 255],
        "aquamarine" => [127, 255, 212],
        "azure" => [240, 255, 255],
        "beige" => [245, 245, 220],
        "bisque" => [255, 228, 196],
        "black" => [0, 0, 0],
        "blanchedalmond" => [255, 235, 205],
        "blue" => [0, 0, 255],
        "blueviolet" => [138, 43, 226],
        "brown" => [165, 42, 42],
        "burlywood" => [222, 184, 135],
        "cadetblue" => [95, 158, 160],
        "chartreuse" => [127, 255, 0],
        "chocolate" => [210, 105, 30],
        "coral" => [255, 127, 80],
        "cornflowerblue" => [100, 149, 237],
        "cornsilk" => [255, 248, 220],
        "crimson" => [220, 20, 60],
        "cyan" => [0, 255, 255],
        "darkblue" => [0, 0, 139],
        "darkcyan" => [0, 139, 139],
        "darkgoldenrod" => [184, 134, 11],
        "darkgray" => [169],
        "darkgreen" => [0, 100, 0],
        "darkgrey" => [169],
        "darkkhaki" => [189, 183, 107],
        "darkmagenta" => [139, 0, 139],
        "darkolivegreen" => [85, 107, 47],
        "darkorange" => [255, 140, 0],
        "darkorchid" => [153, 50, 204],
        "darkred" => [139, 0, 0],
        "darksalmon" => [233, 150, 122],
        "darkseagreen" => [143, 188, 143],
        "darkslateblue" => [72, 61, 139],
        "darkslategray" => [47, 79, 79],
        "darkslategrey" => [47, 79, 79],
        "darkturquoise" => [0, 206, 209],
        "darkviolet" => [148, 0, 211],
        "deeppink" => [255, 20, 147],
        "deepskyblue" => [0, 191, 255],
        "dimgray" => [105],
        "dimgrey" => [105],
        "dodgerblue" => [30, 144, 255],
        "firebrick" => [178, 34, 34],
        "floralwhite" => [255, 250, 240],
        "forestgreen" => [34, 139, 34],
        "fuchsia" => [255, 0, 255],
        "gainsboro" => [220, 220, 220],
        "ghostwhite" => [248, 248, 255],
        "gold" => [255, 215, 0],
        "goldenrod" => [218, 165, 32],
        "gray" => [128],
        "green" => [0, 128, 0],
        "greenyellow" => [173, 255, 47],
        "grey" => [128],
        "honeydew" => [240, 255, 240],
        "hotpink" => [255, 105, 180],
        "indianred" => [205, 92, 92],
        "indigo" => [75, 0, 130],
        "ivory" => [255, 255, 240],
        "khaki" => [240, 230, 140],
        "lavender" => [230, 230, 250],
        "lavenderblush" => [255, 240, 245],
        "lawngreen" => [124, 252, 0],
        "lemonchiffon" => [255, 250, 205],
        "lightblue" => [173, 216, 230],
        "lightcoral" => [240, 128, 128],
        "lightcyan" => [224, 255, 255],
        "lightgoldenrodyellow" => [250, 250, 210],
        "lightgray" => [211],
        "lightgreen" => [144, 238, 144],
        "lightgrey" => [211, 211, 211],
        "lightpink" => [255, 182, 193],
        "lightsalmon" => [255, 160, 122],
        "lightseagreen" => [32, 178, 170],
        "lightskyblue" => [135, 206, 250],
        "lightslategray" => [119, 136, 153],
        "lightslategrey" => [119, 136, 153],
        "lightsteelblue" => [176, 196, 222],
        "lightyellow" => [255, 255, 224],
        "lime" => [0, 255, 0],
        "limegreen" => [50, 205, 50],
        "linen" => [250, 240, 230],
        "magenta" => [255, 0, 255],
        "maroon" => [128, 0, 0],
        "mediumaquamarine" => [102, 205, 170],
        "mediumblue" => [0, 0, 205],
        "mediumorchid" => [186, 85, 211],
        "mediumpurple" => [147, 112, 219],
        "mediumseagreen" => [60, 179, 113],
        "mediumslateblue" => [123, 104, 238],
        "mediumspringgreen" => [0, 250, 154],
        "mediumturquoise" => [72, 209, 204],
        "mediumvioletred" => [199, 21, 133],
        "midnightblue" => [25, 25, 112],
        "mintcream" => [245, 255, 250],
        "mistyrose" => [255, 228, 225],
        "moccasin" => [255, 228, 181],
        "navajowhite" => [255, 222, 173],
        "navy" => [0, 0, 128],
        "oldlace" => [253, 245, 230],
        "olive" => [128, 128, 0],
        "olivedrab" => [107, 142, 35],
        "orange" => [255, 165, 0],
        "orangered" => [255, 69, 0],
        "orchid" => [218, 112, 214],
        "palegoldenrod" => [238, 232, 170],
        "palegreen" => [152, 251, 152],
        "paleturquoise" => [175, 238, 238],
        "palevioletred" => [219, 112, 147],
        "papayawhip" => [255, 239, 213],
        "peachpuff" => [255, 218, 185],
        "peru" => [205, 133, 63],
        "pink" => [255, 192, 203],
        "plum" => [221, 160, 221],
        "powderblue" => [176, 224, 230],
        "purple" => [128, 0, 128],
        "red" => [255, 0, 0],
        "rosybrown" => [188, 143, 143],
        "royalblue" => [65, 105, 225],
        "saddlebrown" => [139, 69, 19],
        "salmon" => [250, 128, 114],
        "sandybrown" => [244, 164, 96],
        "seagreen" => [46, 139, 87],
        "seashell" => [255, 245, 238],
        "sienna" => [160, 82, 45],
        "silver" => [192, 192, 192],
        "skyblue" => [135, 206, 235],
        "slateblue" => [106, 90, 205],
        "slategray" => [112, 128, 144],
        "slategrey" => [112, 128, 144],
        "snow" => [255, 250, 250],
        "springgreen" => [0, 255, 127],
        "steelblue" => [70, 130, 180],
        "tan" => [210, 180, 140],
        "teal" => [0, 128, 128],
        "thistle" => [216, 191, 216],
        "tomato" => [255, 99, 71],
        "turquoise" => [64, 224, 208],
        "violet" => [238, 130, 238],
        "wheat" => [245, 222, 179],
        "white" => [255, 255, 255],
        "whitesmoke" => [245, 245, 245],
        "yellow" => [255, 255, 0],
        "yellowgreen" => [154, 205, 50],
        "hp-blue" => [0, 128, 255],
        "hp-blue-dark" => [28, 91, 216],
        "hp-blue-dark2" => [34, 57, 184],
        "hp-blue-light" => [86, 176, 255],
        "hp-blue-light2" => [185, 220, 255],
        "hp-orange" => [255, 128, 0],
        "hp-orange-light" => [255, 195, 29],
        "hp-orange-light2" => [255, 246, 153],
        "hp-teal" => [0, 140, 130],
        "hp-teal-dark" => [5, 100, 94],
        "hp-teal-dark2" => [6, 70, 63],
        "hp-teal-light" => [75, 177, 176],
        "hp-teal-light2" => [177, 221, 221],
        "hp-gray" => [158],
        "hp-gray-dark" => [97],
        "hp-gray-dark2" => [33],
        "hp-gray-light" => [224],
        "hp-gray-light2" => [245],
      }.freeze

      # :call-seq:
      #   ColorSpace.device_color_from_specification(gray)           => color
      #   ColorSpace.device_color_from_specification(r, g, b)        => color
      #   ColorSpace.device_color_from_specification(c, m, y, k)     => color
      #   ColorSpace.device_color_from_specification(string)         => color
      #   ColorSpace.device_color_from_specification(array)          => color
      #
      # Creates and returns a device color object from the given color specification.
      #
      # There are several ways to define the color that should be used:
      #
      # * A single numeric argument specifies a gray color (see DeviceGray::Color).
      # * Three numeric arguments specify an RGB color (see DeviceRGB::Color).
      # * A string in the format "RRGGBB" where "RR" is the hexadecimal number for the red, "GG"
      #   for the green and "BB" for the blue color value also specifies an RGB color.
      # * As does a string in the format "RGB" where "RR", "GG" and "BB" would be used as the
      #   hexadecimal numbers for the red, green and blue color values of an RGB color.
      # * Any other string is treated as a color name (CSS Color Module Level 3 and HexaPDF design
      #   color names are supported - see COLOR_NAMES).
      # * Four numeric arguments specify a CMYK color (see DeviceCMYK::Color).
      # * An array is treated as if its items were specified separately as arguments.
      #
      # Note that it makes a difference whether integer or float values are used because the given
      # values are first normalized (expected range by the PDF specification is 0.0 - 1.0) - see
      # DeviceGray#color, DeviceRGB#color and DeviceCMYK#color for details.
      #
      # Examples:
      #
      #   #>pdf
      #   cs = HexaPDF::Content::ColorSpace
      #   canvas.line_width(5)
      #
      #   # Note that Canvas#stroke_color implicitly uses this method, so
      #   # explicitly using it like in this example is not needed
      #   canvas.stroke_color(cs.device_color_from_specification(160))
      #   canvas.line(10, 10, 10, 190).stroke
      #   canvas.stroke_color(cs.device_color_from_specification(0, 128, 255))
      #   canvas.line(35, 10, 35, 190).stroke
      #   canvas.stroke_color(cs.device_color_from_specification("0088FF"))
      #   canvas.line(60, 10, 60, 190).stroke
      #   canvas.stroke_color(cs.device_color_from_specification("08F"))
      #   canvas.line(85, 10, 85, 190).stroke
      #   canvas.stroke_color(cs.device_color_from_specification("gold"))
      #   canvas.line(110, 10, 110, 190).stroke
      #   canvas.stroke_color(cs.device_color_from_specification("hp-blue"))
      #   canvas.line(135, 10, 135, 190).stroke
      #   canvas.stroke_color(cs.device_color_from_specification(10, 50, 0, 60))
      #   canvas.line(160, 10, 160, 190).stroke
      #   canvas.stroke_color(cs.device_color_from_specification([0, 128, 255]))
      #   canvas.line(185, 10, 185, 190).stroke
      def self.device_color_from_specification(*spec)
        spec.flatten!
        first_item = spec[0]
        if spec.length == 1 && first_item.kind_of?(String)
          spec = if first_item.match?(/\A\h{6}\z/)
                   first_item.scan(/../).map!(&:hex)
                 elsif first_item.match?(/\A\h{3}\z/)
                   first_item.each_char.map {|x| (x * 2).hex }
                 elsif COLOR_NAMES.key?(first_item)
                   COLOR_NAMES[first_item]
                 else
                   raise ArgumentError, "Given string '#{first_item}' is neither a hex color " \
                     "nor a color name"
                 end
        end
        GlobalConfiguration.constantize('color_space.map', for_components(spec)).new.color(*spec)
      end

      # Serializes the given device color into the form expected by PDF content streams.
      #
      # The +type+ argument can either be :stroke to serialize as stroke color operator or :fill as
      # fill color operator.
      def self.serialize_device_color(color, type: :fill)
        operator = case color.color_space.family
                   when :DeviceRGB then :rg
                   when :DeviceGray then :g
                   when :DeviceCMYK then :k
                   else
                     raise ArgumentError, "Device color object expected, got #{color.class}"
                   end
        operator = operator.upcase if type == :stroke
        Content::Operator::DEFAULT_OPERATORS[operator].
          serialize(HexaPDF::Serializer.new, *color.components)
      end

      # Returns a device color object for the given components array without applying value
      # normalization.
      def self.prenormalized_device_color(components)
        GlobalConfiguration.constantize('color_space.map', for_components(components)).new.
          prenormalized_color(*components)
      end

      # Returns the name of the device color space that should be used for creating a color object
      # from the components array.
      def self.for_components(components)
        case components.length
        when 1 then :DeviceGray
        when 3 then :DeviceRGB
        when 4 then :DeviceCMYK
        else
          raise ArgumentError, "Invalid number of color components, 1|3|4 expected, " \
            "#{components.length} given"
        end
      end

      # This module includes utility functions that are useful for all color classes.
      module ColorUtils

        # Normalizes the given color value so that it is in the range from 0.0 to 1.0.
        #
        # The conversion is done in the following way:
        #
        # * If the color value is an Integer, it is converted to a float and divided by +upper+.
        # * If the color value is greater than 1.0, it is set to 1.0.
        # * If the color value is less than 0.0, it is set to 0.0.
        def normalize_value(value, upper)
          value = value.to_f / upper if value.kind_of?(Integer)
          value.clamp(0, 1)
        end
        private :normalize_value
        module_function :normalize_value

        # Compares this color to another one by looking at their associated color spaces and their
        # components.
        def ==(other)
          other.respond_to?(:components) && other.respond_to?(:color_space) &&
            components == other.components && color_space == other.color_space
        end

      end

      # This class represents a "universal" color space that is used for all color spaces that
      # aren't implemented yet.
      class Universal

        # The color space definition used for creating this universal color space.
        attr_reader :definition

        # Creates the universal color space for the given color space definition.
        def initialize(definition)
          @definition = definition
        end

        # The default universal color.
        def default_color
          Color.new(self)
        end

        # Creates a new universal color object. The number of arguments isn't restricted.
        def color(*args)
          Color.new(self, *args)
        end
        alias prenormalized_color color

        # Returns the PDF color space family this color space belongs to.
        def family
          @definition[0]
        end

        # Compares this universal color space to another one by looking at their definitions.
        def ==(other)
          other.kind_of?(self.class) && definition == other.definition
        end

        # A single color in the universal color space.
        #
        # This doesn't represent a real color but is a place holder for a color in a color space
        # that isn't implemented yet.
        class Color

          include ColorUtils

          # Returns the specific Universal color space used for this color.
          attr_reader :color_space

          # Returns the componets of the universal color, i.e. all arguments provided on
          # initialization.
          attr_reader :components

          # Creates a new universal color with the given components.
          def initialize(color_space, *components)
            @color_space = color_space
            @components = components
          end

        end

      end

      # The DeviceRGB color space.
      class DeviceRGB

        # The one (and only) DeviceRGB color space.
        DEFAULT = new

        # Returns the DeviceRGB color space object.
        def self.new(_definition = nil)
          DEFAULT
        end

        # Returns the default color for the DeviceRGB color space.
        def default_color
          Color.new(0.0, 0.0, 0.0)
        end

        # Returns the color object for the red, green and blue components.
        #
        # Color values can either be integers in the range from 0 to 255 or floating point numbers
        # between 0.0 and 1.0. The integer color values are automatically normalized to the
        # DeviceRGB color value range of 0.0 to 1.0.
        def color(r, g, b)
          Color.new(ColorUtils.normalize_value(r, 255),
                    ColorUtils.normalize_value(g, 255),
                    ColorUtils.normalize_value(b, 255))
        end

        # Returns the color object for the red, green and blue components without applying value
        # normalization.
        #
        # See: #color
        def prenormalized_color(r, g, b)
          Color.new(r, g, b)
        end

        # Returns +:DeviceRGB+.
        def family
          :DeviceRGB
        end
        alias definition family

        # A color in the DeviceRGB color space.
        #
        # See: PDF2.0 s8.6.4.3
        class Color

          include ColorUtils

          # Initializes the color with the +r+ (red), +g+ (green) and +b+ (blue) components.
          #
          # Each argument has to be a float between 0.0 and 1.0.
          def initialize(r, g, b)
            @r = r
            @g = g
            @b = b
          end

          # Returns the DeviceRGB color space module.
          def color_space
            DeviceRGB::DEFAULT
          end

          # Returns the RGB color as an array of normalized color values.
          def components
            [@r, @g, @b]
          end

        end

      end

      # The DeviceCMYK color space.
      class DeviceCMYK

        # The one (and only) DeviceCMYK color space.
        DEFAULT = new

        # Returns the DeviceCMYK color space object.
        def self.new(_definition = nil)
          DEFAULT
        end

        # Returns the default color for the DeviceCMYK color space.
        def default_color
          Color.new(0.0, 0.0, 0.0, 1.0)
        end

        # Returns the color object for the given cyan, magenta, yellow and black components.
        #
        # Color values can either be integers in the range from 0 to 100 or floating point numbers
        # between 0.0 and 1.0. The integer color values are automatically normalized to the
        # DeviceCMYK color value range of 0.0 to 1.0.
        def color(c, m, y, k)
          Color.new(ColorUtils.normalize_value(c, 100), ColorUtils.normalize_value(m, 100),
                    ColorUtils.normalize_value(y, 100), ColorUtils.normalize_value(k, 100))
        end

        # Returns the color object for the cyan, magenta, yellow and black components without
        # applying value normalization.
        #
        # See: #color
        def prenormalized_color(c, m, y, k)
          Color.new(c, m, y, k)
        end

        # Returns +:DeviceCMYK+.
        def family
          :DeviceCMYK
        end
        alias definition family

        # A color in the DeviceCMYK color space.
        #
        # See: PDF2.0 s8.6.4.4
        class Color

          include ColorUtils

          # Initializes the color with the +c+ (cyan), +m+ (magenta), +y+ (yellow) and +k+ (black)
          # components.
          #
          # Each argument has to be a float between 0.0 and 1.0.
          def initialize(c, m, y, k)
            @c = c
            @m = m
            @y = y
            @k = k
          end

          # Returns the DeviceCMYK color space module.
          def color_space
            DeviceCMYK::DEFAULT
          end

          # Returns the CMYK color as an array of normalized color values.
          def components
            [@c, @m, @y, @k]
          end

        end

      end

      # The DeviceGray color space.
      class DeviceGray

        # The one (and only) DeviceGray color space.
        DEFAULT = new

        # Returns the DeviceGray color space object.
        def self.new(_definition = nil)
          DEFAULT
        end

        # Returns the default color for the DeviceGray color space.
        def default_color
          Color.new(0.0)
        end

        # Returns the color object for the given gray component.
        #
        # Color values can either be integers in the range from 0 to 255 or floating point numbers
        # between 0.0 and 1.0. The integer color values are automatically normalized to the
        # DeviceGray color value range of 0.0 to 1.0.
        def color(gray)
          Color.new(ColorUtils.normalize_value(gray, 255))
        end

        # Returns the color object for the gray component without applying value normalization.
        #
        # See: #color
        def prenormalized_color(gray)
          Color.new(gray)
        end

        # Returns +:DeviceGray+.
        def family
          :DeviceGray
        end
        alias definition family

        # A color in the DeviceGray color space.
        #
        # See: PDF2.0 s8.6.4.2
        class Color

          include ColorUtils

          # Initializes the color with the +gray+ component.
          #
          # The argument +gray+ has to be a float between 0.0 and 1.0.
          def initialize(gray)
            @gray = gray
          end

          # Returns the DeviceGray color space module.
          def color_space
            DeviceGray::DEFAULT
          end

          # Returns the normalized gray value as an array.
          def components
            [@gray]
          end

        end

      end

    end

  end
end
