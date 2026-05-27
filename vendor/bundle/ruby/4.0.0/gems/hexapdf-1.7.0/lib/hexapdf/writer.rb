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
require 'hexapdf/serializer'
require 'hexapdf/xref_section'
require 'hexapdf/version'

module HexaPDF

  # Writes the contents of a PDF document to an IO stream.
  class Writer

    # Writes the document to the IO object and returns the last XRefSection written.
    #
    # If +incremental+ is +true+ and the document was created from an existing PDF file, the changes
    # are appended to a full copy of the source document.
    def self.write(document, io, incremental: false)
      if incremental && document.revisions.parser
        new(document, io).write_incremental
      else
        new(document, io).write
      end
    end

    # Creates a new writer object for the given HexaPDF document that gets written to the IO
    # object.
    def initialize(document, io)
      @document = document
      @io = io

      @io.binmode
      @io.seek(0, IO::SEEK_SET) # TODO: incremental update!

      @serializer = Serializer.new
      @serializer.encrypter = @document.encrypted? ? @document.security_handler : nil
      @rev_size = 0

      @use_xref_streams = false
    end

    # Writes the document to the IO object and returns the file position of the start of the last
    # cross-reference section and the last XRefSection written.
    def write
      move_modified_objects_into_current_revision
      write_file_header

      pos = xref_section = nil
      @document.trailer.info[:Producer] = "HexaPDF version #{HexaPDF::VERSION}"
      @document.revisions.each do |rev|
        pos, xref_section = write_revision(rev, pos)
      end

      [pos, xref_section]
    end

    # Writes the complete source document unmodified to the IO and then one revision containing all
    # changes. Returns the file position of the start of the cross-reference section and the
    # XRefSection object of that one revision.
    #
    # For this method to work the document must have been created from an existing file.
    def write_incremental
      parser = @document.revisions.parser

      _, orig_trailer = parser.load_revision(parser.startxref_offset)
      orig_trailer = @document.wrap(orig_trailer, type: :XXTrailer)
      if @document.revisions.current.trailer[:Encrypt]&.value != orig_trailer[:Encrypt]&.value
        raise HexaPDF::Error, "Used encryption cannot be modified when doing incremental writing"
      end

      parser.io.seek(0, IO::SEEK_SET)
      IO.copy_stream(parser.io, @io)
      @io << "\n"

      @rev_size = @document.revisions.current.next_free_oid
      @use_xref_streams = @document.revisions.any? {|rev| rev.trailer[:Type] == :XRef }

      revision = Revision.new(@document.revisions.current.trailer)
      @document.trailer.info[:Producer] = "HexaPDF version #{HexaPDF::VERSION}"
      if parser.file_header_version < @document.version
        @document.catalog[:Version] = @document.version.to_sym
      end
      @document.revisions.each do |rev|
        rev.each_modified_object(all: true) {|obj| revision.send(:add_without_check, obj) }
      end

      write_revision(revision, parser.startxref_offset)
    end

    private

    # Writes the PDF file header.
    #
    # See: PDF2.0 s7.5.2
    def write_file_header
      @io << "%PDF-#{@document.version}\n%\xCF\xEC\xFF\xE8\xD7\xCB\xCD\n"
    end

    # Moves all modified objects into the current revision to avoid invalid references and such.
    def move_modified_objects_into_current_revision
      return if @document.revisions.count == 1

      revision = @document.revisions.add
      @document.revisions.all[0..-2].each do |rev|
        rev.each_modified_object(delete: true) {|obj| revision.send(:add_without_check, obj) }
      end
      @document.revisions.merge(-2..-1)
    end

    # Writes the given revision.
    #
    # The optional +previous_xref_pos+ argument needs to contain the byte position of the previous
    # cross-reference section or stream if applicable.
    def write_revision(rev, previous_xref_pos = nil)
      xref_stream, object_streams = xref_and_object_streams(rev)
      obj_to_stm = object_streams.each_with_object({}) {|stm, m| m.update(stm.write_objects(rev)) }

      xref_section = XRefSection.new
      xref_section.mark_as_initial_section! unless previous_xref_pos
      rev.each do |obj|
        if obj.null?
          xref_section.add_free_entry(obj.oid, obj.gen)
        elsif (objstm = obj_to_stm[obj])
          xref_section.add_compressed_entry(obj.oid, objstm.oid, objstm.object_index(obj))
        elsif obj != xref_stream
          xref_section.add_in_use_entry(obj.oid, obj.gen, @io.pos)
          write_indirect_object(obj)
        end
      end

      trailer = rev.trailer.value.dup
      trailer.delete(:XRefStm)
      trailer.delete(:Type)
      if previous_xref_pos
        trailer[:Prev] = previous_xref_pos
      else
        trailer.delete(:Prev)
      end
      @rev_size = rev.next_free_oid if rev.next_free_oid > @rev_size
      trailer[:Size] = @rev_size

      startxref = @io.pos
      if xref_stream
        xref_section.add_in_use_entry(xref_stream.oid, xref_stream.gen, startxref)
        xref_stream.update_with_xref_section_and_trailer(xref_section, trailer)
        write_indirect_object(xref_stream)
      else
        write_xref_section(xref_section)
        write_trailer(trailer)
      end

      write_startxref(startxref)

      [startxref, xref_section]
    end

    # :call-seq:
    #    writer.xref_and_object_streams    -> [xref_stream, object_streams]
    #
    # Returns the cross-reference and object streams of the given revision.
    #
    # An error is raised if the revision contains object streams and no cross-reference stream. If
    # it contains multiple cross-reference streams only the first one is used, the rest are
    # ignored.
    def xref_and_object_streams(rev)
      xref_stream = nil
      object_streams = []

      rev.each do |obj|
        if obj.type == :ObjStm
          object_streams << obj
        elsif !xref_stream && obj.type == :XRef
          xref_stream = obj
        end
      end

      if (!object_streams.empty? || @use_xref_streams) && xref_stream.nil?
        xref_stream = @document.wrap({}, type: Type::XRefStream, oid: @document.revisions.next_oid)
        rev.add(xref_stream)
      end

      @use_xref_streams = true if xref_stream

      [xref_stream, object_streams]
    end

    # Writes the single indirect object which may be a stream object or another object.
    def write_indirect_object(obj)
      @io << "#{obj.oid} #{obj.gen} obj\n"
      @serializer.serialize_to_io(obj, @io)
      @io << "\nendobj\n"
    end

    # Writes the cross-reference section.
    #
    # See: PDF2.0 s7.5.4
    def write_xref_section(xref_section)
      @io << "xref\n"
      xref_section.each_subsection do |entries|
        @io << "#{entries.empty? ? 0 : entries.first.oid} #{entries.size}\n"
        entries.each do |entry|
          if entry.in_use?
            @io << sprintf("%010d %05d n \n", entry.pos, entry.gen).freeze
          elsif entry.free?
            @io << "0000000000 65535 f \n"
          else
            # Should never occur since we create the xref section!
            raise HexaPDF::Error, "Cannot use xref type #{entry.type} in cross-reference section"
          end
        end
      end
    end

    # Writes the trailer dictionary.
    #
    # See: PDF2.0 s7.5.5
    def write_trailer(trailer)
      @io << "trailer\n#{@serializer.serialize(trailer)}\n"
    end

    # Writes the startxref line needed for cross-reference sections and cross-reference streams.
    #
    # See: PDF2.0 s7.5.5, s7.5.8
    def write_startxref(startxref)
      @io << "startxref\n#{startxref}\n%%EOF\n"
    end

  end

end
