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
require 'hexapdf/parser'
require 'hexapdf/revision'
require 'hexapdf/type/trailer'

module HexaPDF

  # Manages the revisions of a PDF document.
  #
  # A PDF document has one revision when it is created. Later, new revisions are added when changes
  # are made. This allows for adding information/content to a PDF file without changing the original
  # content.
  #
  # The order of the revisions is important. In HexaPDF the oldest revision always has index 0 and
  # the newest revision the highest index. This is also the order in which the revisions get
  # written.
  #
  # *Important*: It is possible to manipulate the individual revisions and their objects oneself but
  # this should only be done if one is familiar with the inner workings of HexaPDF. Otherwise it is
  # best to use the convenience methods of this class to create, access or delete indirect objects.
  #
  # See: PDF2.0 s7.5.6, HexaPDF::Revision
  class Revisions

    class << self

      # Loads all revisions for the document from the given IO and returns the created Revisions
      # object.
      #
      # If the +io+ object is +nil+, an empty Revisions object is returned.
      def from_io(document, io)
        return new(document) if io.nil?

        parser = Parser.new(io, document)
        object_loader = lambda {|xref_entry| parser.load_object(xref_entry) }

        revisions = []
        begin
          offset = parser.startxref_offset
          seen_xref_offsets = {}

          while offset && !seen_xref_offsets.key?(offset)
            # PDF2.0 s7.5.5 states that :Prev needs to be indirect, Adobe's reference 3.4.4 says it
            # should be direct. Adobe's POV is followed here. Same with :XRefStm.
            xref_section, trailer = parser.load_revision(offset)
            seen_xref_offsets[offset] = true

            stm = trailer[:XRefStm]
            if stm && !seen_xref_offsets.key?(stm)
              if xref_section.max_oid == 0 && trailer[:Prev] > stm
                # Revision is completely empty, with xref stream in previous revision
                merge_revision = trailer[:Prev]
              end
              stm_xref_section, = parser.load_revision(stm)
              stm_xref_section.merge!(xref_section)
              xref_section = stm_xref_section
              seen_xref_offsets[stm] = true
            end

            if parser.linearized? && !trailer.key?(:Prev)
              merge_revision = offset
            end

            if merge_revision == offset && !revisions.empty?
              xref_section.merge!(revisions.first.xref_section)
              offset = trailer[:Prev] # Get possible next offset before overwriting trailer
              trailer = revisions.first.trailer
              revisions.shift
            else
              offset = trailer[:Prev]
            end

            revisions.unshift(Revision.new(document.wrap(trailer, type: :XXTrailer),
                                           xref_section: xref_section, loader: object_loader))
          end
        rescue HexaPDF::MalformedPDFError
          raise unless (reconstructed_revision = parser.reconstructed_revision)
          unless revisions.empty?
            reconstructed_revision.trailer.data.value = revisions.last.trailer.data.value
          end
          revisions << reconstructed_revision
        end

        document.version = parser.file_header_version rescue '1.0'
        new(document, initial_revisions: revisions, parser: parser)
      end

    end

    include Enumerable

    # The Parser instance used for reading the initial revisions.
    attr_reader :parser

    # Creates a new revisions object for the given PDF document.
    #
    # Options:
    #
    # initial_revisions::
    #     An array of revisions that should initially be used. If this option is not specified, a
    #     single empty revision is added.
    #
    # parser::
    #     The parser with which the initial revisions were read. If this option is not specified
    #     even though the document was read from an IO stream, some parts may not work, like
    #     incremental writing.
    def initialize(document, initial_revisions: nil, parser: nil)
      @document = document
      @parser = parser

      @revisions = []
      if initial_revisions
        @revisions += initial_revisions
      else
        add
      end
    end

    # Returns the next object identifier that should be used when adding a new object.
    def next_oid
      @revisions.map(&:next_free_oid).max
    end

    # :call-seq:
    #   revisions.object(ref)    -> obj or nil
    #   revisions.object(oid)    -> obj or nil
    #
    # Returns the current version of the indirect object for the given exact reference or for the
    # given object number.
    #
    # For references to unknown objects, +nil+ is returned but free objects are represented by a
    # PDF Null object, not by +nil+!
    #
    # See: PDF2.0 s7.3.9
    def object(ref)
      i = @revisions.size - 1
      while i >= 0
        if (result = @revisions[i].object(ref))
          return result
        end
        i -= 1
      end
      nil
    end

    # :call-seq:
    #   revisions.object?(ref)    -> true or false
    #   revisions.object?(oid)    -> true or false
    #
    # Returns +true+ if one of the revisions contains an indirect object for the given exact
    # reference or for the given object number.
    #
    # Even though this method might return +true+ for some references, #object may return +nil+
    # because this method takes *all* revisions into account.
    def object?(ref)
      @revisions.any? {|rev| rev.object?(ref) }
    end

    # :call-seq:
    #   revisions.add_object(object)     -> object
    #
    # Adds the given HexaPDF::Object to the current revision and returns it.
    #
    # If +object+ is a direct object, an object number is automatically assigned.
    def add_object(obj)
      if obj.indirect? && (rev_obj = current.object(obj.oid))
        if rev_obj.data == obj.data
          return obj
        else
          raise HexaPDF::Error, "Can't add object because there is already " \
            "an object with object number #{obj.oid}"
        end
      end

      obj.oid = next_oid unless obj.indirect?
      current.add(obj)
    end

    # :call-seq:
    #   revisions.delete_object(ref)
    #   revisions.delete_object(oid)
    #
    # Deletes the indirect object specified by an exact reference or by an object number.
    def delete_object(ref)
      @revisions.reverse_each do |rev|
        if rev.object?(ref)
          rev.delete(ref)
          break
        end
      end
    end

    # :call-seq:
    #   revisions.each_object(only_current: true, only_loaded: false) {|obj| block }      -> revisions
    #   revisions.each_object(only_current: true, only_loaded: false) {|obj, rev| block } -> revisions
    #   revisions.each_object(only_current: true, only_loaded: false)                     -> Enumerator
    #
    # Yields every object and optionally the revision it is in.
    #
    # If +only_loaded+ is +true+, only the already loaded objects of the PDF document are yielded.
    # This does only matter when the document instance was created from an existing PDF document.
    #
    # By default, only the current version of each object is returned which implies that each object
    # number is yielded exactly once. If the +only_current+ option is +false+, all stored objects
    # from newest to oldest are returned, not only the current version of each object.
    #
    # The +only_current+ option can make a difference because the document can contain multiple
    # revisions:
    #
    # * Multiple revisions may contain objects with the same object and generation numbers, e.g.
    #   two (different) objects with oid/gen [3,0].
    #
    # * Additionally, there may also be objects with the same object number but different
    #   generation numbers in different revisions, e.g. one object with oid/gen [3,0] and one with
    #   oid/gen [3,1].
    #
    # *Note* that setting +only_current+ to +false+ is normally not necessary and should not be
    # done. If it is still done, one has to take care to avoid an invalid document state.
    def each_object(only_current: true, only_loaded: false, &block)
      unless block_given?
        return to_enum(__method__, only_current: only_current, only_loaded: only_loaded)
      end

      yield_rev = (block.arity == 2)
      oids = {}
      @revisions.reverse_each do |rev|
        rev.each(only_loaded: only_loaded) do |obj|
          next if only_current && oids.include?(obj.oid)
          yield_rev ? yield(obj, rev) : yield(obj)
          oids[obj.oid] = true
        end
      end
      self
    end

    # Returns the current revision.
    #
    # *Note*: This method should only be used if one is familiar with the inner workings of HexaPDF
    # *and the PDF specification.
    def current
      @revisions.last
    end

    # Returns a list of all revisions.
    #
    # *Note*: This method should only be used if one is familiar with the inner workings of HexaPDF
    # *and the PDF specification.
    def all
      @revisions
    end

    # :call-seq:
    #   revisions.each {|rev| block }   -> revisions
    #   revisions.each                  -> Enumerator
    #
    # Iterates over all revisions from oldest to current one.
    #
    # *Note*: This method should only be used if one is familiar with the inner workings of HexaPDF
    # *and the PDF specification.
    def each(&block)
      return to_enum(__method__) unless block_given?
      @revisions.each(&block)
      self
    end

    # Adds a new empty revision to the document and returns it.
    #
    # *Note*: This method should only be used if one is familiar with the inner workings of HexaPDF
    # *and the PDF specification.
    def add
      if @revisions.empty?
        trailer = {}
      else
        trailer = current.trailer.value.dup
        trailer.delete(:Prev)
        trailer.delete(:XRefStm)
      end

      rev = Revision.new(@document.wrap(trailer, type: :XXTrailer))
      @revisions.push(rev)
      rev
    end

    # :call-seq:
    #   revisions.merge(range = 0..-1)    -> revisions
    #
    # Merges the revisions specified by the given range into one. Objects from newer revisions
    # overwrite those from older ones.
    def merge(range = 0..-1)
      @revisions[range].reverse.each_cons(2) do |rev, prev_rev|
        prev_rev.trailer.value.replace(rev.trailer.value)
        rev.each do |obj|
          if obj.data != prev_rev.object(obj)&.data
            prev_rev.delete(obj.oid, mark_as_free: false)
            prev_rev.add(obj)
          end
        end
      end
      _first, *other = *@revisions[range]
      other.each {|rev| @revisions.delete(rev) }
      self
    end

  end

end
