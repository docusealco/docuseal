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
require 'hexapdf/content/graphics_state'
require 'hexapdf/utils/bit_stream'

module HexaPDF
  module ImageLoader

    # This class is used for loading images in the PNG format from files or IO streams.
    #
    # It can handle all five types of PNG images: greyscale w/wo alpha, truecolor w/wo alpha and
    # indexed-color. Furthermore, it recognizes the gAMA, cHRM, sRGB and tRNS chunks and handles
    # them appropriately. However, Adam7 interlaced images are not supported!
    #
    # Note that greyscale, truecolor and indexed-color images with alpha need to be decoded to get
    # the alpha channel which takes time.
    #
    # All PNG specification section references are in reference to http://www.w3.org/TR/PNG/.
    #
    # See: PDF2.0 s7.4.4., s8.9
    class PNG

      # The magic marker that tells us if the file/IO contains an image in PNG format.
      #
      # See: PNG s5.2
      MAGIC_FILE_MARKER = "\x89PNG\r\n\x1A\n".b

      # The color type for PNG greyscale images without alpha, see PNG s11.2.2
      GREYSCALE = 0

      # The color type for PNG truecolor images without alpha, see PNG s11.2.2
      TRUECOLOR = 2

      # The color type for PNG indexed images with/without alpha, see PNG s11.2.2
      INDEXED   = 3

      # The color type for PNG greyscale images with alpha, see PNG s11.2.2
      GREYSCALE_ALPHA = 4

      # The color type for PNG truecolor images with alpha, see PNG s11.2.2
      TRUECOLOR_ALPHA = 6

      # Mapping from sRGB chunk rendering intent byte to PDF rendering intent name.
      RENDERING_INTENT_MAP = {
        0 => Content::RenderingIntent::PERCEPTUAL,
        1 => Content::RenderingIntent::RELATIVE_COLORIMETRIC,
        2 => Content::RenderingIntent::SATURATION,
        3 => Content::RenderingIntent::ABSOLUTE_COLORIMETRIC,
      }.freeze

      # The primary chromaticities and white point used by the sRGB specification.
      SRGB_CHRM = [0.3127, 0.329, 0.64, 0.33, 0.3, 0.6, 0.15, 0.06].freeze

      # :call-seq:
      #   PNG.handles?(filename)     -> true or false
      #   PNG.handles?(io)           -> true or false
      #
      # Returns +true+ if the given file or IO stream can be handled, ie. if it contains an image
      # in PNG format.
      def self.handles?(file_or_io)
        if file_or_io.kind_of?(String)
          File.read(file_or_io, 8, mode: 'rb') == MAGIC_FILE_MARKER
        else
          file_or_io.rewind
          file_or_io.read(8) == MAGIC_FILE_MARKER
        end
      end

      # :call-seq:
      #   PNG.load(document, filename)    -> image_obj
      #   PNG.load(document, io)          -> image_obj
      #
      # Creates a PDF image object from the PNG file or IO stream.
      def self.load(document, file_or_io)
        new(document, file_or_io).load
      end

      def initialize(document, io) #:nodoc:
        @document = document
        @io = io

        @color_type = nil
        @intent = nil
        @chrm = nil
        @gamma = nil
      end

      def load #:nodoc:
        with_io do |io|
          io.seek(8, IO::SEEK_SET)

          dict = {
            Type: :XObject,
            Subtype: :Image,
          }

          while true
            length, type = io.read(8).unpack('Na4') # PNG s5.3

            case type
            when 'IDAT' # PNG s11.2.4
              idat_offset = io.pos - 8
              break
            when 'IHDR' # PNG s11.2.2
              values = io.read(length).unpack('NNC5')
              dict[:Width] = values[0]
              dict[:Height] = values[1]
              dict[:BitsPerComponent] = values[2]
              @color_type = values[3]

              if values[4] != 0
                raise HexaPDF::Error, "Unsupported PNG compression method"
              elsif values[5] != 0
                raise HexaPDF::Error, "Unsupported PNG filter method"
              elsif values[6] != 0
                raise HexaPDF::Error, "Unsupported PNG interlace method"
              end
            when 'PLTE' # PNG s11.2.3
              if @color_type == INDEXED
                palette = io.read(length)
                hival = (palette.size / 3) - 1
                if dict[:BitsPerComponent] == 8
                  palette = @document.add({Filter: :FlateDecode}, stream: palette)
                end
                dict[:ColorSpace] = [:Indexed, color_space, hival, palette]
              else
                io.seek(length, IO::SEEK_CUR)
              end
            when 'tRNS' # PNG s11.3.2
              case @color_type
              when INDEXED
                trns = io.read(length).unpack('C*')
              when TRUECOLOR, GREYSCALE
                dict[:Mask] = io.read(length).unpack('n*').map {|val| [val, val] }.flatten
              else
                io.seek(length, IO::SEEK_CUR)
              end
            when 'sRGB' # PNG s11.3.3.5
              @intent = io.read(length).unpack1('C')
              dict[:Intent] = RENDERING_INTENT_MAP[@intent]
              @chrm = SRGB_CHRM
              @gamma = 2.2
            when 'gAMA' # PNG s11.3.3.2
              gamma = 100_000.0 / io.read(length).unpack1('N')
              unless @intent || gamma == 1.0 # sRGB trumps gAMA
                @gamma = gamma
                @chrm ||= SRGB_CHRM # don't overwrite data from a cHRM chunk
              end
            when 'cHRM' # PNG s11.3.3.1
              chrm = io.read(length)
              @chrm = chrm.unpack('N8').map {|v| v / 100_000.0 } unless @intent # sRGB trumps cHRM
            else
              io.seek(length, IO::SEEK_CUR)
            end

            io.seek(4, IO::SEEK_CUR) # don't check the CRC
          end

          dict[:ColorSpace] ||= color_space

          decode_parms = {
            Predictor: 15,
            Colors: @color_type == TRUECOLOR || @color_type == TRUECOLOR_ALPHA ? 3 : 1,
            BitsPerComponent: dict[:BitsPerComponent],
            Columns: dict[:Width],
          }

          if @color_type == TRUECOLOR_ALPHA || @color_type == GREYSCALE_ALPHA
            image_data, mask_data = separate_alpha_channel(idat_offset, decode_parms)
            add_smask_image(dict, mask_data)
            stream = HexaPDF::StreamData.new(lambda { image_data },
                                             filter: :FlateDecode,
                                             decode_parms: decode_parms)
          else
            if @color_type == INDEXED && trns
              mask_data = alpha_mask_for_indexed_image(idat_offset, decode_parms, trns)
              add_smask_image(dict, mask_data, from_indexed: true)
            end
            stream = HexaPDF::StreamData.new(image_data_proc(idat_offset),
                                             filter: :FlateDecode,
                                             decode_parms: decode_parms)
          end

          obj = @document.add(dict, stream: stream)
          obj.set_filter(:FlateDecode, decode_parms)
          obj
        end
      end

      private

      # Yields the IO object for reading the PNG image.
      #
      # Automatically handles files and IO streams.
      def with_io
        io = (@io.kind_of?(String) ? File.new(@io, 'rb') : @io)
        yield(io)
      ensure
        io.close if @io.kind_of?(String)
      end

      # Returns the PDF color space definition that should be used with the PDF image of the PNG
      # file.
      #
      # In the case of an indexed PNG image, this returns the definition for the color space
      # underlying the palette.
      def color_space
        if @color_type == GREYSCALE || @color_type == GREYSCALE_ALPHA
          if @gamma
            [:CalGray, {WhitePoint: [1.0, 1.0, 1.0], Gamma: @gamma}]
          else
            :DeviceGray
          end
        elsif @gamma || @chrm
          dict = @chrm ? calrgb_definition_from_chrm(*@chrm) : {}
          if @gamma
            dict[:Gamma] = [@gamma, @gamma, @gamma]
            dict[:WhitePoint] ||= [1.0, 1.0, 1.0]
          end
          [:CalRGB, dict]
        else
          :DeviceRGB
        end
      end

      # Returns a hash for a CalRGB color space definition using the x,y chromaticity coordinates
      # of the white point and the red, green and blue primaries.
      #
      # See: PDF2.0 s8.6.5.3
      def calrgb_definition_from_chrm(xw, yw, xr, yr, xg, yg, xb, yb)
        z = yw * ((xg - xb) * yr - (xr - xb) * yg + (xr - xg) * yb)

        mya = yr * ((xg - xb) * yw - (xw - xb) * yg + (xw - xg) * yb) / z
        mxa = mya * xr / yr
        mza = mya * ((1 - xr) / yr - 1)

        myb = - (yg * ((xr - xb) * yw - (xw - xb) * yr + (xw - xr) * yb)) / z
        mxb = myb * xg / yg
        mzb = myb * ((1 - xg) / yg - 1)
        myc = yb * ((xr - xg) * yw - (xw - xg) * yr + (xw - xr) * yg) / z
        mxc = myc * xb / yb
        mzc = myc * ((1 - xb) / yb - 1)

        mxw = mxa + mxb + mxc
        myw = 1.0 # mya + myb + myc
        mzw = mza + mzb + mzc

        {WhitePoint: [mxw, myw, mzw], Matrix: [mxa, mya, mza, mxb, myb, mzb, mxc, myc, mzc]}
      end

      # Adds a source mask image to the image described by +dict+ using +mask_data+ as the source
      # data.
      #
      # If the optional argument +from_indexed+ is +true+, it is assumed that the +mask_data+ was
      # created from an indexed PNG and is not deflate encoded.
      def add_smask_image(dict, mask_data, from_indexed: false)
        decode_parms = {
          Predictor: 15,
          Colors: 1,
          BitsPerComponent: (from_indexed ? 8 : dict[:BitsPerComponent]),
          Columns: dict[:Width],
        }
        stream_opts = (from_indexed ? {} : {filter: :FlateDecode, decode_parms: decode_parms})
        stream = HexaPDF::StreamData.new(lambda { mask_data }, **stream_opts)

        smask_dict = {
          Type: :XObject,
          Subtype: :Image,
          Width: dict[:Width],
          Height: dict[:Height],
          ColorSpace: :DeviceGray,
          BitsPerComponent: (from_indexed ? 8 : dict[:BitsPerComponent]),
        }
        smask = @document.add(smask_dict, stream: stream)
        smask.set_filter(:FlateDecode, decode_parms)
        dict[:SMask] = smask
      end

      # Returns a Proc object that can be used with a StreamData object to read the image data.
      #
      # This method is efficient because it doesn't need to uncompress or filter the image data
      # but it only works for PNG images without embedded alpha channel data.
      def image_data_proc(offset)
        lambda do
          with_io do |io|
            io.seek(offset, IO::SEEK_SET)

            while true
              length, type = io.read(8).unpack('Na4') # PNG s5.3
              break if type != 'IDAT'

              chunk_size = @document.config['io.chunk_size']
              while length > 0
                chunk_size = length if chunk_size > length
                Fiber.yield(io.read(chunk_size))
                length -= chunk_size
              end
              io.seek(4, IO::SEEK_CUR)
            end
          end

          nil
        end
      end

      # Separates the color data from the alpha data and returns an array containing the image and
      # alpha data, both deflate encoded with predictor.
      #
      # Since we need to decompress the PNG chunks and extract the color/alpha bytes this method
      # is not very fast but gets the job done as fast as possible in plain Ruby.
      def separate_alpha_channel(offset, decode_parms)
        bytes_per_colors = (decode_parms[:BitsPerComponent] * decode_parms[:Colors] + 7) / 8
        bytes_per_alpha = (decode_parms[:BitsPerComponent] + 7) / 8
        bytes_per_row = (decode_parms[:Columns] * decode_parms[:BitsPerComponent] *
          (decode_parms[:Colors] + 1) + 7) / 8 + 1
        image_data = ''.b
        mask_data = ''.b

        flate_decode = @document.config.constantize('filter.map', :FlateDecode)
        source = flate_decode.decoder(Fiber.new(&image_data_proc(offset)))

        data = ''.b
        while source.alive? && (new_data = source.resume)
          data << new_data
          while data.length >= bytes_per_row
            i = 1
            image_data << data.getbyte(0)
            mask_data << data.getbyte(0)
            while i < bytes_per_row
              bytes_per_colors.times {|j| image_data << data.getbyte(i + j) }
              i += bytes_per_colors
              bytes_per_alpha.times {|j| mask_data << data.getbyte(i + j) }
              i += bytes_per_alpha
            end
            data = data[bytes_per_row..-1]
          end
        end

        image_data = Filter.string_from_source(flate_decode.encoder(Fiber.new { image_data }))
        mask_data = Filter.string_from_source(flate_decode.encoder(Fiber.new { mask_data }))

        [image_data, mask_data]
      end

      # Creates the alpha mask source data for an indexed PNG with alpha values.
      #
      # The returned data is *not* deflate encoded!
      def alpha_mask_for_indexed_image(offset, decode_parms, trns)
        width = decode_parms[:Columns]
        bpc = decode_parms[:BitsPerComponent]
        bytes_per_row = (width * bpc + 7) / 8 + 1

        flate_decode = @document.config.constantize('filter.map', :FlateDecode)
        source = flate_decode.decoder(Fiber.new(&image_data_proc(offset)))

        mask_data = ''.b
        stream = HexaPDF::Utils::BitStreamReader.new
        while source.alive? && (data = source.resume)
          stream.append_data(data)

          while stream.remaining_bits / 8 >= bytes_per_row
            stream.read(8) # read filter byte
            i = 0
            while i < width
              index = stream.read(bpc)
              mask_data << (trns[index] || 255)
              i += 1
            end
            stream.read(8 - ((width * bpc) % 8)) if bpc != 8 # read remaining fill bits
          end
        end

        mask_data
      end

    end

  end
end
