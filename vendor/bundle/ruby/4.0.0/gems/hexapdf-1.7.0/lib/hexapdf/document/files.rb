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

module HexaPDF
  class Document

    # This class provides methods for managing file specifications of a PDF file.
    #
    # Note that for a given PDF file not all file specifications may be found, e.g. when a file
    # specification is only a string. Therefore this module can only handle those file
    # specifications that are indirect file specification dictionaries with the /Type key set.
    class Files

      include Enumerable

      # Creates a new Files object for the given PDF document.
      def initialize(document)
        @document = document
      end

      # :call-seq:
      #   files.add(filename, name: nil, description: nil, embed: true) -> file_spec
      #   files.add(io, name:, description: nil)                        -> file_spec
      #
      # Adds the file or IO to the PDF document and returns the corresponding file specification
      # object.
      #
      # Options:
      #
      # name::
      #     The name that should be used for the file path. This name is also used for registering
      #     the file in the EmbeddedFiles name tree.
      #
      #     When a filename is given, the basename of the file is used by default for +name+ if it
      #     is not specified.
      #
      # description::
      #     A description of the file.
      #
      # mime_type::
      #     The MIME type that should be set for embedded files (so only used if +embed+ is +true+).
      #
      # embed::
      #     When an IO object is given, it is always embedded and this option is ignored.
      #
      #     When a filename is given and this option is +true+, then the file is embedded. Otherwise
      #     only a reference to it is stored.
      #
      # See: HexaPDF::Type::FileSpecification
      def add(file_or_io, name: nil, description: nil, mime_type: nil, embed: true)
        name ||= File.basename(file_or_io) if file_or_io.kind_of?(String)
        if name.nil?
          raise ArgumentError, "The name argument is mandatory when given an IO object"
        end

        spec = @document.add({Type: :Filespec})
        spec.path = name
        spec[:Desc] = description if description
        if embed || !file_or_io.kind_of?(String)
          spec.embed(file_or_io, name: name, mime_type: mime_type, register: true)
        end
        spec
      end

      # :call-seq:
      #   files.each(search: false) {|file_spec| block }   -> files
      #   files.each(search: false)                        -> Enumerator
      #
      # Iterates over indirect file specification dictionaries of the PDF.
      #
      # By default, only the file specifications in their standard locations, i.e. in the
      # EmbeddedFiles name tree and in the page annotations, are returned. If the +search+ option is
      # +true+, then all indirect objects are searched for file specification dictionaries which can
      # be much slower.
      def each(search: false)
        return to_enum(__method__, search: search) unless block_given?

        if search
          @document.each do |obj|
            yield(obj) if obj.type == :Filespec
          end
        else
          seen = {}
          tree = @document.catalog[:Names] && @document.catalog[:Names][:EmbeddedFiles]
          tree&.each_entry do |_, spec|
            seen[spec] = true
            yield(spec)
          end

          @document.pages.each do |page|
            page.each_annotation do |annot|
              next unless annot[:Subtype] == :FileAttachment
              spec = annot[:FS]
              yield(spec) unless seen.key?(spec)
              seen[spec] = true
            end
          end
        end

        self
      end

    end

  end
end
