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
require 'hexapdf/document'

module HexaPDF
  module ImageLoader

    # This module is used for loading the first page of a PDF file.
    #
    # Loaded PDF graphics are represented by form XObjects instead of image XObjects. However, the
    # image/xobject drawing methods of HexaPDF::Content::Canvas know how to handle them correctly so
    # that this doesn't matter from a user's point of view.
    #
    # See: PDF2.0 s8.10
    module PDF

      # The magic marker that tells us if the file/IO contains an PDF file.
      MAGIC_FILE_MARKER = "%PDF-".b

      # :call-seq:
      #   PDF.handles?(filename)     -> true or false
      #   PDF.handles?(io)           -> true or false
      #
      # Returns +true+ if the given file or IO stream can be handled, ie. if it contains an image
      # in JPEG format.
      def self.handles?(file_or_io)
        if file_or_io.kind_of?(String)
          File.read(file_or_io, 5, mode: 'rb') == MAGIC_FILE_MARKER
        else
          file_or_io.rewind
          file_or_io.read(5) == MAGIC_FILE_MARKER
        end
      end

      # :call-seq:
      #   PDF.load(document, filename)    -> form_obj
      #   PDF.load(document, io)          -> form_obj
      #
      # Creates a PDF form XObject from the PDF file or IO stream.
      #
      # See: DefaultConfiguration for the meaning of 'image_loader.pdf.use_stringio'.
      def self.load(document, file_or_io)
        idoc = if file_or_io.kind_of?(String) && document.config['image_loader.pdf.use_stringio']
                 HexaPDF::Document.open(file_or_io)
               elsif file_or_io.kind_of?(String)
                 HexaPDF::Document.new(io: File.open(file_or_io, 'rb'))
               else
                 HexaPDF::Document.new(io: file_or_io)
               end
        form = idoc.pages[0].to_form_xobject
        document.add(document.import(form))
      end

    end

  end
end
