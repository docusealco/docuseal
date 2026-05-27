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

require 'hexapdf/cli/command'

module HexaPDF
  module CLI

    # Converts one or more images into a PDF file.
    class Image2PDF < Command

      def initialize #:nodoc:
        super('image2pdf', takes_commands: false)
        short_desc("Convert one or more images into a PDF file")
        long_desc(<<~EOF)
          This command converts one or more images into a single PDF file. The various options allow
          setting a page size, scaling the images and defining margins.
        EOF

        options.on("-p", "--page-size SIZE", "The PDF page size. Either auto which chooses a " \
                   "size based on the image size or a valid page size like A4, A4-landscape " \
                   "or 595x842. Default: auto") do |page_size|
          @media_box = case page_size
                       when 'auto'
                         :auto
                       when /(\d+(?:\.\d+)?)x(\d+(?:\.\d+)?)/
                         [0, 0, $1.to_f, $2.to_f]
                       else
                         orientation = :portrait
                         if page_size.end_with?('-landscape')
                           orientation = :landscape
                           page_size.delete_suffix!('-landscape')
                         end
                         page_size = page_size.capitalize.to_sym
                         HexaPDF::Type::Page.media_box(page_size, orientation: orientation)
                       end
        end
        options.on("--[no-]auto-rotate", "Automatically rotate pages based on image dimesions. " \
                   "Default: true") do |auto_rotate|
          @auto_rotate = auto_rotate
        end
        options.on("-s", "--scale SCALE", Integer, "Defines how the images should be scaled. " \
                   "Either fit to fit the image to the page size or a number specifying the " \
                   "minimum pixels per inch. Default: fit") do |scale|
          @scale = case scale
                   when 'fit' then :fit
                   else scale.to_f
                   end
        end
        options.on("-m", "--margins MARGINS", Array, "Defines the margins around the image, " \
                   "either with a single number or four numbers (top, right, bottom, left) " \
                   "separated by commas. Default: 0") do |margins|
          @margins = case margins.size
                     when 1 then margins.map!(&:to_f) * 4
                     when 4 then margins.map!(&:to_f)
                     else
                       raise OptionParser::InvalidArgument, "#{margins.join(',')} (1 or 4 " \
                         "numbers needed)"
                     end
        end
        define_optimization_options
        define_encryption_options

        @media_box = :auto
        @auto_rotate = true
        @scale = :fit
        @margins = [0, 0, 0, 0]
      end

      def execute(*images, out_file) #:nodoc:
        maybe_raise_on_existing_file(out_file)

        out = HexaPDF::Document.new

        images.each do |image_file|
          image = out.images.add(image_file)
          iw = image.width.to_f
          ih = image.height.to_f
          if @scale != :fit
            iw *= 72 / @scale
            ih *= 72 / @scale
          end

          media_box = (@media_box == :auto ? [0, 0, iw, ih] : @media_box.dup)
          if @auto_rotate && (ih > iw) != (media_box[3] > media_box[2]) &&
              (iw > media_box[2] || ih > media_box[3])
            media_box[2], media_box[3] = media_box[3], media_box[2]
          end
          page = out.pages.add(media_box)

          pw = page.box(:media).width.to_f - @margins[1] - @margins[3]
          ph = page.box(:media).height.to_f - @margins[0] - @margins[2]
          if @scale == :fit || iw > pw || ih > ph
            ratio = [pw / iw, ph / ih].min
            iw, ih = iw * ratio, ih * ratio
          end
          x, y = @margins[3] + (pw - iw) / 2, @margins[2] + (ph - ih) / 2
          page.canvas.image(image, at: [x, y], width: iw, height: ih)
        end

        apply_encryption_options(out)
        apply_optimization_options(out)
        write_document(out, out_file)
      end

    end

  end
end
