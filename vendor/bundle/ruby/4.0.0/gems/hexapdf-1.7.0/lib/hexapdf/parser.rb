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
require 'hexapdf/tokenizer'
require 'hexapdf/stream'
require 'hexapdf/xref_section'

module HexaPDF

  # Parses an IO stream according to PDF2.0 to get at the contained objects.
  #
  # This class also contains higher-level methods for getting indirect objects and revisions.
  #
  # See: PDF2.0 s7
  class Parser

    # The IO stream which is parsed.
    attr_reader :io

    # Creates a new parser for the given IO object.
    #
    # PDF references are resolved using the associated Document object.
    def initialize(io, document)
      @io = io
      on_correctable_error = document.config['parser.on_correctable_error'].curry[document]
      @tokenizer = Tokenizer.new(io, on_correctable_error: on_correctable_error)
      @document = document
      @object_stream_data = {}
      @reconstructed_revision = nil
      @in_reconstruct_revision = false
      retrieve_pdf_header_offset_and_version
    end

    # Returns +true+ if the PDF file was damaged and could be reconstructed.
    def reconstructed?
      !@reconstructed_revision.nil?
    end

    # Returns +true+ if the PDF file is a linearized file.
    #
    # Note: The method uses heuristics to determine whether a PDF file is linearized. In case of
    # slightly invalid or damaged PDFs that HexaPDF can recover from it is possible that this method
    # returns +true+ even though the PDF isn't actually linearized.
    def linearized?
      @linearized ||=
        begin
          @tokenizer.pos = @header_offset
          3.times { @tokenizer.next_token } # parse: oid gen obj
          obj = @tokenizer.next_object
          obj.kind_of?(Hash) && obj.key?(:Linearized)
        rescue MalformedPDFError
          false
        end
    end

    # Loads the indirect (potentially compressed) object specified by the given cross-reference
    # entry.
    #
    # For information about the +xref_entry+ argument, have a look at HexaPDF::XRefSection and
    # HexaPDF::XRefSection::Entry.
    def load_object(xref_entry)
      obj, oid, gen, stream =
        case xref_entry.type
        when :in_use
          if xref_entry.pos == 0 && xref_entry.oid != 0
            # Handle seen-in-the-wild objects with invalid offset 0
            maybe_raise("Indirect object (#{xref_entry.oid},#{xref_entry.gen}) has offset 0", pos: 0)
            [nil, xref_entry.oid, xref_entry.gen, nil]
          else
            parse_indirect_object(xref_entry.pos)
          end
        when :free
          [nil, xref_entry.oid, xref_entry.gen, nil]
        when :compressed
          load_compressed_object(xref_entry)
        else
          raise_malformed("Invalid cross-reference type '#{xref_entry.type}' encountered")
        end

      if xref_entry.oid != 0 && (oid != xref_entry.oid || gen != xref_entry.gen)
        msg = "The oid,gen (#{oid},#{gen}) values of the indirect object don't match " \
              "the values (#{xref_entry.oid},#{xref_entry.gen}) from the xref"
        # Some invalid PDFs contain entries where the generation number in the xref is different
        # from the one found in the indirect object. If the file were reconstructed the generation
        # number from the indirect object itself would be used.
        # To gracefully handle such invalid PDFs they need to have a single revision.
        # The other code part that handles this is in Revision#object.
        if oid == xref_entry.oid && @document.revisions.count == 1
          maybe_raise(msg, pos: xref_entry.pos)
        else
          raise_malformed(msg)
        end
      end

      if obj.kind_of?(Reference)
        @document.deref(obj)
      else
        @document.wrap(obj, oid: oid, gen: gen, stream: stream)
      end
    rescue HexaPDF::MalformedPDFError
      reconstructed_revision.object(xref_entry) ||
        @document.wrap(nil, oid: xref_entry.oid, gen: xref_entry.gen)
    end

    # Parses the indirect object at the specified offset.
    #
    # This method is used by a PDF Document to load objects. It should **not** be used by any
    # other object because invalid object positions lead to errors.
    #
    # Returns an array containing [object, oid, gen, stream].
    #
    # See: PDF2.0 s7.3.10, s7.3.8
    def parse_indirect_object(offset = nil)
      @tokenizer.pos = offset + @header_offset if offset
      oid = @tokenizer.next_token
      gen = @tokenizer.next_token
      tok = @tokenizer.next_token
      unless oid.kind_of?(Integer) && gen.kind_of?(Integer) &&
          tok.kind_of?(Tokenizer::Token) && tok == 'obj'
        raise_malformed("No valid object found", pos: offset)
      end

      if (tok = @tokenizer.peek_token) && tok.kind_of?(Tokenizer::Token) && tok == 'endobj'
        maybe_raise("No indirect object value between 'obj' and 'endobj'", pos: @tokenizer.pos)
        object = nil
      else
        begin
          object = @tokenizer.next_object
        rescue MalformedPDFError
          if tok.kind_of?(Tokenizer::Token) && tok =~ /\A\d+endobj\z/
            # Handle often found invalid indirect object with missing whitespace after number
            maybe_raise("Missing whitespace after number'", pos: @tokenizer.pos)
            object = tok.to_i
            @tokenizer.pos -= 6
          else
            maybe_raise("Invalid value after '#{oid} #{gen} obj', treating as null", pos: @tokenizer.pos)
            return [nil, oid, gen, nil]
          end
        end
      end

      tok = @tokenizer.next_token

      if tok.kind_of?(Tokenizer::Token) && tok == 'stream'
        unless object.kind_of?(Hash)
          raise_malformed("A stream needs a dictionary, not a(n) #{object.class}", pos: offset)
        end
        tok1 = @tokenizer.next_byte
        if tok1 == 32 # space
          maybe_raise("Keyword stream followed by space instead of LF or CR/LF", pos: @tokenizer.pos)
          tok1 = @tokenizer.next_byte
        end
        tok2 = @tokenizer.next_byte if tok1 == 13 # CR
        if tok1 != 10 && tok1 != 13
          raise_malformed("Keyword stream must be followed by LF or CR/LF", pos: @tokenizer.pos)
        elsif tok1 == 13 && tok2 != 10
          maybe_raise("Keyword stream must be followed by LF or CR/LF, not CR alone",
                      pos: @tokenizer.pos)
          @tokenizer.pos -= 1
        end

        # Note that getting :Length might move the IO pointer (when resolving references)
        pos = @tokenizer.pos
        length = if object[:Length].kind_of?(Integer)
                   object[:Length]
                 elsif object[:Length].kind_of?(Reference)
                   @document.deref(object[:Length])&.value || 0
                 else
                   0
                 end
        @tokenizer.pos = pos + length rescue pos

        tok = @tokenizer.next_token rescue nil
        unless tok.kind_of?(Tokenizer::Token) && tok == 'endstream'
          maybe_raise("Invalid stream length, keyword endstream not found", pos: @tokenizer.pos)
          @tokenizer.pos = pos
          if @tokenizer.scan_until(/(?=\n?endstream)/)
            length = @tokenizer.pos - pos
            tok = @tokenizer.next_token
          else
            raise_malformed("Stream content must be followed by keyword endstream",
                            pos: @tokenizer.pos)
          end
        end
        tok = @tokenizer.next_token

        object[:Length] = length
        if object.key?(:Filter)
          begin
            object[:Filter] = @document.unwrap(object[:Filter])
          rescue HexaPDF::Error
            maybe_raise("Invalid /Filter entry for stream", pos: @tokenizer.pos)
            object.delete(:Filter)
          end
        end
        if object.key?(:DecodeParms)
          begin
            object[:DecodeParms] = @document.unwrap(object[:DecodeParms])
          rescue HexaPDF::Error
            maybe_raise("Invalid /DecodeParms entry for stream", pos: @tokenizer.pos)
            object.delete(:DecodeParms)
          end
        end
        stream = StreamData.new(@tokenizer.io, offset: pos, length: length,
                                filter: object[:Filter], decode_parms: object[:DecodeParms])
      end

      unless tok.kind_of?(Tokenizer::Token) && tok == 'endobj'
        maybe_raise("Indirect object must be followed by keyword endobj", pos: @tokenizer.pos)
      end

      [object, oid, gen, stream]
    end

    # Loads the compressed object identified by the cross-reference entry.
    def load_compressed_object(xref_entry)
      unless @object_stream_data.key?(xref_entry.objstm)
        obj = @document.object(xref_entry.objstm)
        unless obj.respond_to?(:parse_stream)
          raise_malformed("Object with oid=#{xref_entry.objstm} is not an object stream")
        end
        @object_stream_data[xref_entry.objstm] = obj.parse_stream
      end

      [*@object_stream_data[xref_entry.objstm].object_by_index(xref_entry.pos), xref_entry.gen, nil]
    end

    # Loads a single revision whose cross-reference section/stream is located at the given
    # position.
    #
    # Returns an HexaPDF::XRefSection object and the accompanying trailer dictionary.
    def load_revision(pos)
      if xref_section?(pos)
        xref_section, trailer = parse_xref_section_and_trailer(pos)
      else
        obj = load_object(XRefSection.in_use_entry(0, 0, pos))
        unless obj.respond_to?(:xref_section)
          raise_malformed("Object is not a cross-reference stream", pos: pos)
        end
        begin
          xref_section = obj.xref_section
        rescue MalformedPDFError => e
          e.pos = pos
          raise
        end
        trailer = obj.trailer
        unless xref_section.entry?(obj.oid, obj.gen)
          maybe_raise("Cross-reference stream doesn't contain entry for itself", pos: pos)
          xref_section.add_in_use_entry(obj.oid, obj.gen, pos)
        end
      end
      xref_section.delete(0)
      [xref_section, trailer]
    end

    # Looks at the given offset and returns +true+ if there is a cross-reference section at that
    # position.
    def xref_section?(offset)
      @tokenizer.pos = offset + @header_offset
      token = @tokenizer.peek_token
      token.kind_of?(Tokenizer::Token) && token == 'xref'
    end

    # Parses the cross-reference section at the given position and the following trailer and
    # returns them as an array consisting of an HexaPDF::XRefSection instance and a hash.
    #
    # This method can only parse cross-reference sections, not cross-reference streams!
    #
    # See: PDF2.0 s7.5.4, s7.5.5; ADB1.7 sH.3-3.4.3
    def parse_xref_section_and_trailer(offset)
      @tokenizer.pos = offset + @header_offset
      token = @tokenizer.next_token
      unless token.kind_of?(Tokenizer::Token) && token == 'xref'
        raise_malformed("Xref section doesn't start with keyword xref", pos: @tokenizer.pos)
      end

      xref = XRefSection.new
      start = @tokenizer.next_token
      while start.kind_of?(Integer)
        number_of_entries = @tokenizer.next_token
        unless number_of_entries.kind_of?(Integer)
          raise_malformed("Invalid cross-reference subsection start", pos: @tokenizer.pos)
        end

        @tokenizer.skip_whitespace
        start.upto(start + number_of_entries - 1) do |oid|
          pos, gen, type = @tokenizer.next_xref_entry do |recoverable|
            maybe_raise("Invalid cross-reference entry", pos: @tokenizer.pos,
                        force: !recoverable)
          end
          if xref.entry?(oid)
            next
          elsif type == 'n'
            if pos == 0 || gen > 65535
              maybe_raise("Invalid in use cross-reference entry for object number #{oid}",
                          pos: @tokenizer.pos)
              xref.add_free_entry(oid, gen)
            else
              xref.add_in_use_entry(oid, gen, pos)
            end
          else
            xref.add_free_entry(oid, gen)
          end
        end
        start = @tokenizer.next_token
      end

      unless start.kind_of?(Tokenizer::Token) && start == 'trailer'
        raise_malformed("Trailer doesn't start with keyword trailer", pos: @tokenizer.pos)
      end

      trailer = @tokenizer.next_object
      unless trailer.kind_of?(Hash)
        raise_malformed("Trailer is #{trailer.class} instead of dictionary ", pos: @tokenizer.pos)
      end

      unless trailer[:Prev] || xref.max_oid == 0 || xref.entry?(0)
        first_entry = xref[xref.oids[0]]
        test_entry = xref[xref.oids[-1]]
        @tokenizer.pos = test_entry.pos + @header_offset
        test_oid = @tokenizer.next_token
        first_oid = first_entry.oid

        force_failure = !first_entry.free? || first_entry.gen != 65535 ||
          !test_oid.kind_of?(Integer) || xref.oids[-1] - test_oid != first_oid
        maybe_raise("Main cross-reference section has invalid numbering",
                    pos: offset + @header_offset, force: force_failure)

        new_xref = XRefSection.new
        xref.oids.each do |oid|
          entry = xref[oid]
          entry.oid -= first_oid
          new_xref.send(:[]=, entry.oid, entry.gen, entry)
        end
        xref = new_xref
      end

      [xref, trailer]
    end

    # Returns the offset of the main cross-reference section/stream.
    #
    # Implementation note: Normally, the %%EOF marker has to be on the last line, however, Adobe
    # viewers relax this restriction and so do we.
    #
    # If strict parsing is disabled, the whole file is searched for the offset.
    #
    # See: PDF2.0 s7.5.5, ADB1.7 sH.3-3.4.4
    def startxref_offset
      return @startxref_offset if defined?(@startxref_offset)

      @io.seek(0, IO::SEEK_END)
      step_size = 1024
      pos = @io.pos
      eof_not_found = pos == 0
      startxref_missing = startxref_mangled = false
      startxref_offset = nil

      while pos != 0
        @io.pos = [pos - step_size, 0].max
        pos = @io.pos
        lines = @io.read(step_size + 40).split(/[\r\n]+/)

        # Need to iterate through the whole lines array in case there are multiple %%EOF to try
        eof_index = 0
        while (eof_index = lines[0..(eof_index - 1)].rindex {|l| l.strip == '%%EOF' })
          if eof_index > 0 && lines[eof_index - 1].strip =~ /\Astartxref\s(\d+)\z/
            startxref_offset = $1.to_i
            startxref_mangled = true
            break # we found it even if it the syntax is not entirely correct
          elsif eof_index < 2
            startxref_missing = true
            break
          elsif lines[eof_index - 2].strip != "startxref"
            startxref_missing = true
          else
            startxref_offset = lines[eof_index - 1].to_i
            break # we found it
          end
        end
        eof_not_found ||= !eof_index
        break if startxref_offset
      end

      if startxref_mangled
        maybe_raise("PDF file trailer keyword startxref on same line as value", pos: pos)
      elsif startxref_missing
        maybe_raise("PDF file trailer is missing startxref keyword", pos: pos,
                    force: !startxref_offset)
      elsif eof_not_found
        maybe_raise("PDF file trailer with end-of-file marker not found", pos: pos,
                    force: !startxref_offset)
      end

      @startxref_offset = startxref_offset
    end

    # Returns the reconstructed revision.
    def reconstructed_revision
      @reconstructed_revision ||= reconstruct_revision
    end

    # Returns the PDF version number that is stored in the file header.
    #
    # See: PDF2.0 s7.5.2
    def file_header_version
      unless @header_version
        raise_malformed("PDF file header is missing or corrupt", pos: 0)
      end
      @header_version
    end

    private

    # Retrieves the offset of the PDF header and the PDF version number in it.
    #
    # The PDF header should normally appear on the first line. However, Adobe relaxes this
    # restriction so that the header may appear in the first 1024 bytes. We follow the Adobe
    # convention.
    #
    # See: PDF2.0 s7.5.2, ADB1.7 sH.3-3.4.1
    def retrieve_pdf_header_offset_and_version
      @io.seek(0)
      @header_offset = (@io.read(1024) || '').index(/%PDF-(\d\.\d)/) || 0
      @header_version = $1
    end

    # Tries to reconstruct the PDF document's main cross-reference table by serially parsing the
    # file and returning a Revision object for loading the found objects.
    #
    # If the file contains multiple cross-reference sections, all objects will be put into a single
    # cross-reference table, later objects overwriting prior ones.
    def reconstruct_revision
      return if @in_reconstruct_revision
      @in_reconstruct_revision = true
      @header_offset = 0

      raise unless @document.config['parser.try_xref_reconstruction']
      msg = "#{$!} - trying cross-reference table reconstruction"
      @document.config['parser.on_correctable_error'].call(@document, msg, @tokenizer.pos)

      xref = XRefSection.new
      @tokenizer.pos = 0
      linearized = nil
      while true
        @tokenizer.skip_whitespace
        pos = @tokenizer.pos
        @tokenizer.scan_until(/(\n|\r\n?)+|\z/)
        next_new_line_pos = @tokenizer.pos
        @tokenizer.pos = pos

        token = @tokenizer.next_integer_or_keyword rescue nil
        if token.kind_of?(Integer)
          gen = @tokenizer.next_integer_or_keyword rescue nil
          tok = @tokenizer.next_integer_or_keyword rescue nil
          if @tokenizer.pos > next_new_line_pos
            @tokenizer.pos = next_new_line_pos
          elsif gen.kind_of?(Integer) && tok.kind_of?(Tokenizer::Token) && tok == 'obj'
            xref.add_in_use_entry(token, gen, pos)
            if linearized.nil?
              pos = @tokenizer.pos
              obj = @tokenizer.next_object rescue nil
              linearized = obj.kind_of?(Hash) && obj.key?(:Linearized)
              @tokenizer.pos = pos
            end
            @tokenizer.scan_until(/\bendobj\b/)
          end
        elsif token.kind_of?(Tokenizer::Token) && token == 'trailer'
          obj = @tokenizer.next_object rescue nil
          # Use last trailer found in case of multiple revisions but use first trailer in case of
          # linearized file.
          trailer = obj if obj.kind_of?(Hash) && (!linearized || trailer.nil?)
        elsif token == Tokenizer::NO_MORE_TOKENS
          break
        else
          @tokenizer.pos = next_new_line_pos
        end
      end

      if !trailer || trailer.empty?
        _, trailer = load_revision(startxref_offset) rescue nil
        unless trailer
          xref.each do |_oid, _gen, xref_entry|
            obj, * = parse_indirect_object(xref_entry.pos) rescue nil
            if obj.kind_of?(Hash) && obj[:Type] == :Catalog
              trailer = {Root: HexaPDF::Reference.new(xref_entry.oid, xref_entry.gen)}
              break
            end
          end
        end
        unless trailer
          @in_reconstruct_revision = false
          raise_malformed("Could not reconstruct malformed PDF because trailer was not found", pos: 0)
        end
      end
      trailer&.delete(:Prev) # no need for this and may wreak havoc

      loader = lambda do |xref_entry|
        obj, oid, gen, stream = parse_indirect_object(xref_entry.pos)
        obj = @document.wrap(obj, oid: oid, gen: gen, stream: stream)
        @document.security_handler ? @document.security_handler.decrypt(obj) : obj
      end

      @in_reconstruct_revision = false
      Revision.new(@document.wrap(trailer, type: :XXTrailer), xref_section: xref,
                   loader: loader)
    end

    # Raises a HexaPDF::MalformedPDFError with the given message and source position.
    def raise_malformed(msg, pos: nil)
      raise HexaPDF::MalformedPDFError.new(msg, pos: pos)
    end

    # Calls the block stored in the config option +parser.on_correctable_error+ with the document,
    # the given message and the position. If the returned value is +true+, raises a
    # HexaPDF::MalformedPDFError. Otherwise the error is corrected and parsing continues.
    #
    # If the option +force+ is used, the block is not called and the error is raised immediately.
    def maybe_raise(msg, pos:, force: false)
      if force || @document.config['parser.on_correctable_error'].call(@document, msg, pos)
        error = HexaPDF::MalformedPDFError.new(msg, pos: pos)
        error.set_backtrace(caller(1))
        raise error
      end
    end

  end

end
