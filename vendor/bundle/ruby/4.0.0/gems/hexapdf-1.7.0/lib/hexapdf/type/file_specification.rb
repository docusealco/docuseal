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

require 'uri'
require 'hexapdf/dictionary'
require 'hexapdf/stream'

module HexaPDF
  module Type

    # Represents a file specification dictionary.
    #
    # File specifications are used to refer to other files or URLs from within a PDF file. Simple
    # file specifications are just strings. However, the are automatically converted on access to
    # a full file specification to provide a unified interface.
    #
    # == Working with File Specifications
    #
    # A file specification may refer to a file or an URL. This can easily be checked with #url?.
    # Independent of whether the file specification referes to an URL or a file, the #path method
    # returns the "best" useable path for it.
    #
    # Modifying a file specification should be done via the #path= and #url= methods as they
    # ensure that no obsolescent entries are used and the file specification is consistent.
    #
    # Finally, since embedded files in a PDF document are always linked to a file specification it
    # is useful to provide embedding/unembedding operations in this class, see #embed and
    # #unembed.
    #
    # See: PDF2.0 s7.11
    class FileSpecification < Dictionary

      # The type used for the /EF field of a FileSpecification
      class EFDictionary < Dictionary

        define_type :XXFilespecEFDictionary

        define_field :F,    type: :EmbeddedFile
        define_field :UF,   type: :EmbeddedFile
        define_field :DOS,  type: :EmbeddedFile
        define_field :Mac,  type: :EmbeddedFile
        define_field :Unix, type: :EmbeddedFile

      end

      define_type :Filespec

      define_field :Type,  type: Symbol, default: type, required: true
      define_field :FS,    type: Symbol
      define_field :F,     type: PDFByteString
      define_field :UF,    type: String, version: '1.7'
      define_field :DOS,   type: PDFByteString
      define_field :Mac,   type: PDFByteString
      define_field :Unix,  type: PDFByteString
      define_field :ID,    type: PDFArray
      define_field :V,     type: Boolean, version: '1.2'
      define_field :EF,    type: :XXFilespecEFDictionary, version: '1.7'
      define_field :RF,    type: Dictionary, version: '1.3'
      define_field :Desc,  type: String, version: '1.6'
      define_field :CI,    type: Dictionary, version: '1.7'
      define_field :Thumb, type: Stream, version: '2.0'
      define_field :EP,    type: Dictionary, version: '2.0'
      define_field :AF,    type: Symbol, version: '2.0', default: :Unspecified

      # Returns +true+ if this file specification references an URL and not a file.
      def url?
        self[:FS] == :URL
      end

      # Returns the path for the referenced file or URL. An empty string is returned if no file
      # specification string is set.
      #
      # If multiple file specification strings are available, the fields are search in the
      # following order and the first one with a value is used: /UF, /F, /Unix, /Mac, /DOS.
      #
      # The encoding of the returned path string is either UTF-8 (for /UF) or BINARY (for /F
      # /Unix, /Mac and /DOS).
      def path
        tmp = (self[:UF] || self[:F] || self[:Unix] || self[:Mac] || self[:DOS] || '').dup
        tmp.gsub!(/\\\//, "/") # PDF2.0 s7.11.2.1 but / in filename is interpreted as separator!
        tmp.tr!("\\", "/") # always use slashes instead of back-slashes!
        tmp
      end

      # Sets the file specification string to the given filename.
      #
      # Since the /Unix, /Mac and /DOS fields are deprecated, only the /F and /UF fields are set.
      def path=(filename)
        self[:UF] = filename
        self[:F] = filename.b
        delete(:FS)
        delete(:Unix)
        delete(:Mac)
        delete(:DOS)
      end

      # Sets the file specification string to the given URL and updates the file system entry
      # appropriately.
      #
      # The provided URL needs to be in an RFC1738 compliant string representation. If not, an
      # error is raised.
      def url=(url)
        begin
          URI(url)
        rescue URI::InvalidURIError => e
          raise HexaPDF::Error, e
        end
        self.path = url
        self[:FS] = :URL
      end

      # Returns +true+ if this file specification contains an embedded file.
      #
      # See: #embedded_file_stream
      def embedded_file?
        key?(:EF) && !self[:EF].empty?
      end

      # Returns the embedded file associated with this file specification, or +nil+ if this file
      # specification references no embedded file.
      #
      # If there are multiple possible embedded files, the /EF fields are searched in the following
      # order and the first one with a value is used: /UF, /F, /Unix, /Mac, /DOS.
      def embedded_file_stream
        return unless key?(:EF)
        ef = self[:EF]
        ef[:UF] || ef[:F] || ef[:Unix] || ef[:Mac] || ef[:DOS]
      end

      # :call-seq:
      #   file_spec.embed(filename, name: File.basename(filename), mime_type: nil, register: true)   -> ef_stream
      #   file_spec.embed(io, name:, mime_type: nil, register: true)                                 -> ef_stream
      #
      # Embeds the given file or IO stream into the PDF file, sets the path and MIME type
      # accordingly and returns the created stream object.
      #
      # If a file is given, the +name+ option defaults to the basename of the file. However, if an
      # IO object is given, the +name+ argument is mandatory.
      #
      # If there already was a file embedded for this file specification, it is unembedded first.
      #
      # The embedded file stream automatically uses the FlateEncode filter for compressing the
      # embedded file.
      #
      # Options:
      #
      # name::
      #     The name that should be used as path value and when registering.
      #
      # mime_type::
      #     Optionally specifies the MIME type of the file.
      #
      # register::
      #     Specifies whether the embedded file will be added to the EmbeddedFiles name tree under
      #     the +name+. If the name is already taken, it's value is overwritten.
      #
      # The file has to be available until the PDF document gets written because reading and
      # writing is done lazily.
      def embed(file_or_io, name: nil, mime_type: nil, register: true)
        name ||= File.basename(file_or_io) if file_or_io.kind_of?(String)
        if name.nil?
          raise ArgumentError, "The name argument is mandatory when given an IO object"
        end

        unembed
        self.path = name

        self[:EF] ||= {}
        ef_stream = self[:EF][:UF] = self[:EF][:F] = document.add({Type: :EmbeddedFile})
        ef_stream[:Subtype] = mime_type.to_sym if mime_type
        stat = if file_or_io.kind_of?(String)
                 File.stat(file_or_io)
               elsif file_or_io.respond_to?(:stat)
                 file_or_io.stat
               end
        if stat
          ef_stream[:Params] = {Size: stat.size, CreationDate: stat.ctime, ModDate: stat.mtime}
        end
        ef_stream.set_filter(:FlateDecode)
        ef_stream.stream = HexaPDF::StreamData.new(file_or_io)

        if register
          (document.catalog[:Names] ||= {})[:EmbeddedFiles] ||= {}
          document.catalog[:Names][:EmbeddedFiles].add_entry(name, self)
        end

        ef_stream
      end

      # Deletes any embedded file streams associated with this file specification. A possible entry
      # in the EmbeddedFiles name tree is also deleted.
      def unembed
        return unless key?(:EF)
        self[:EF].each {|_, ef_stream| document.delete(ef_stream) }

        if document.catalog.key?(:Names) && document.catalog[:Names].key?(:EmbeddedFiles)
          tree = document.catalog[:Names][:EmbeddedFiles]
          tree.each_entry.find_all {|_, spec| spec == self }.each do |(name, _)|
            tree.delete_entry(name)
          end
        end
      end

    end

  end
end
