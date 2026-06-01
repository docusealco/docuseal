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

require 'hexapdf/configuration'

module HexaPDF
  class Document

    # This class provides methods for managing the images embedded in a PDF file. It is available
    # through the HexaPDF::Document#images method.
    #
    # Images themselves are represented by the HexaPDF::Type::Image class.Since an image can be used
    # as a mask for another image, not all image objects found in a PDF are really used as images.
    # Such cases are all handled by this class automatically.
    class Images

      include Enumerable

      # Creates a new Images object for the given PDF document.
      def initialize(document)
        @document = document
      end

      # :call-seq:
      #   images.add(file)            -> image
      #   images.add(io)              -> image
      #
      # Adds the image from the given file or IO to the PDF document and returns the image object.
      #
      # If the image has been added to the PDF before (i.e. if there is an image object with the
      # same path name), the already existing image object is returned.
      def add(file_or_io)
        name = if file_or_io.kind_of?(String)
                 file_or_io
               elsif file_or_io.respond_to?(:to_path)
                 file_or_io.to_path
               end
        if name
          name = File.absolute_path(name)
          image = find {|im| im.source_path == name }
        end
        unless image
          image = image_loader_for(file_or_io).load(@document, file_or_io)
          image.source_path = name
        end
        image
      end

      # :call-seq:
      #   images.each {|image| block }   -> images
      #   images.each                    -> Enumerator
      #
      # Iterates over all images in the PDF document.
      #
      # Note that only real images are yielded which means, for example, that images used as soft
      # mask are not.
      def each(&block)
        images = @document.each.select do |obj|
          next unless obj.kind_of?(HexaPDF::Dictionary)
          obj[:Subtype] == :Image && !obj[:ImageMask]
        end
        masks = images.each_with_object([]) do |image, temp|
          temp << image[:Mask] if image[:Mask].kind_of?(Stream)
          temp << image[:SMask] if image[:SMask].kind_of?(Stream)
        end
        (images - masks).each(&block)
      end

      private

      # Returns the image loader (see HexaPDF::ImageLoader) for the given file or IO stream or
      # raises an error if no suitable image loader is found.
      def image_loader_for(file_or_io)
        @document.config['image_loader'].each_index do |index|
          loader = @document.config.constantize('image_loader', index) do
            raise HexaPDF::Error, "Couldn't retrieve image loader from configuration"
          end
          return loader if loader.handles?(file_or_io)
        end

        raise HexaPDF::Error, "Couldn't find suitable image loader"
      end

    end

  end
end
