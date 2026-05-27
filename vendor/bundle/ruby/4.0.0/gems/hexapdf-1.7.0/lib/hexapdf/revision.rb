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
require 'hexapdf/utils/object_hash'

module HexaPDF

  # Embodies one revision of a PDF file, either the initial version or an incremental update.
  #
  # The purpose of a Revision object is to manage the objects and the trailer of one revision.
  # These objects can either be added manually or loaded from a cross-reference section or stream.
  # Since a PDF file can be incrementally updated, it can have multiple revisions.
  #
  # If a revision doesn't have an associated cross-reference section, it wasn't created from a PDF
  # file.
  #
  # See: PDF2.0 s7.5.6, Revisions
  class Revision

    include Enumerable

    # The trailer dictionary
    attr_reader :trailer

    # The callable object responsible for loading objects.
    attr_accessor :loader

    # The associated XRefSection object.
    attr_reader :xref_section

    # :call-seq:
    #   Revision.new(trailer)                                           -> revision
    #   Revision.new(trailer, xref_section: section, loader: loader)    -> revision
    #   Revision.new(trailer, xref_section: section) {|entry| block }   -> revision
    #
    # Creates a new Revision object.
    #
    # Options:
    #
    # xref_section::
    #   An XRefSection object that contains information on how to load objects. If this option is
    #   specified, then a +loader+ or a block also needs to be specified!
    #
    # loader::
    #   The loader object needs to respond to +call+ taking a cross-reference entry and returning
    #   the loaded object. If no +xref_section+ is supplied, this value is not used.
    #
    #   If a block is given, it is used instead of the loader object.
    def initialize(trailer, xref_section: nil, loader: nil, &block)
      @trailer = trailer
      @loader = xref_section && (block || loader)
      @xref_section = xref_section || XRefSection.new
      @objects = HexaPDF::Utils::ObjectHash.new
      @all_objects_loaded = false
    end

    # Returns the next free object number for adding an object to this revision.
    def next_free_oid
      ((a = @xref_section.max_oid) < (b = @objects.max_oid) ? b : a) + 1
    end

    # :call-seq:
    #   revision.xref(ref)    -> xref_entry or nil
    #   revision.xref(oid)    -> xref_entry or nil
    #
    # Returns an XRefSection::Entry structure for the given reference or object number if it is
    # available, or +nil+ otherwise.
    def xref(ref)
      if ref.respond_to?(:oid)
        @xref_section[ref.oid, ref.gen]
      else
        @xref_section[ref, nil]
      end
    end

    # :call-seq:
    #   revision.object(ref)    -> obj or nil
    #   revision.object(oid)    -> obj or nil
    #
    # Returns the object for the given reference or object number if such an object is available
    # in this revision, or +nil+ otherwise.
    #
    # If the revision has an entry but one that is pointing to a free entry in the cross-reference
    # section, an object representing PDF null is returned.
    def object(ref)
      if ref.respond_to?(:oid)
        oid = ref.oid
        gen = ref.gen
      else
        oid = ref
      end

      if @objects.entry?(oid, gen)
        @objects[oid, gen]
      elsif (xref_entry = @xref_section[oid, gen])
        load_object(xref_entry)
      elsif (xref_entry = @xref_section[oid]) && (obj = load_object(xref_entry))&.gen == gen
        # This branch handles invalid PDFs with a single revision containing xref entries where the
        # gen doesn't match the gen of the indirect object. Also see the special handling in
        # Parser#load_object.
        obj
      else
        nil
      end
    end

    # :call-seq:
    #   revision.object?(ref)    -> true or false
    #   revision.object?(oid)    -> true or false
    #
    # Returns +true+ if the revision contains an object
    #
    # * for the exact reference if the argument responds to :oid, or else
    # * for the given object number.
    def object?(ref)
      if ref.respond_to?(:oid)
        @objects.entry?(ref.oid, ref.gen) || @xref_section.entry?(ref.oid, ref.gen)
      else
        @objects.entry?(ref) || @xref_section.entry?(ref)
      end
    end

    # :call-seq:
    #   revision.add(obj)   -> obj
    #
    # Adds the given object (needs to be a HexaPDF::Object) to this revision and returns it.
    def add(obj)
      if object?(obj.oid)
        raise HexaPDF::Error, "A revision can only contain one object with a given object number"
      elsif !obj.indirect?
        raise HexaPDF::Error, "A revision can only contain indirect objects"
      end
      add_without_check(obj)
    end

    # :call-seq:
    #   revision.update(obj)   -> obj or nil
    #
    # Updates the stored object to point to the given HexaPDF::Object wrapper, returning the object
    # if successful or +nil+ otherwise.
    #
    # If +obj+ isn't stored in this revision or the stored object doesn't contain the same
    # HexaPDF::PDFData object as the given object, nothing is done.
    #
    # This method should only be used if the wrong wrapper class is stored (e.g. because
    # auto-detection didn't or couldn't work correctly) and thus needs correction.
    def update(obj)
      return nil if object(obj)&.data != obj.data
      add_without_check(obj)
    end

    # :call-seq:
    #   revision.delete(ref, mark_as_free: true)
    #   revision.delete(oid, mark_as_free: true)
    #
    # Deletes the object specified either by reference or by object number from this revision by
    # marking it as free.
    #
    # If the +mark_as_free+ option is set to +false+, the object is really deleted.
    def delete(ref_or_oid, mark_as_free: true)
      return unless object?(ref_or_oid)
      ref_or_oid = ref_or_oid.oid if ref_or_oid.respond_to?(:oid)

      obj = object(ref_or_oid)
      obj.data.value = nil
      obj.document = nil
      if mark_as_free
        add_without_check(HexaPDF::Object.new(obj.data))
      else
        @xref_section.delete(ref_or_oid)
        @objects.delete(ref_or_oid)
      end
    end

    # :call-seq:
    #   revision.each(only_loaded: false) {|obj| block }   -> revision
    #   revision.each(only_loaded: false)                  -> Enumerator
    #
    # Calls the given block for every object of the revision, or, if +only_loaded+ is +true+, for
    # every already loaded object.
    #
    # Objects that are loadable via an associated cross-reference section but are currently not
    # loaded, are loaded automatically if +only_loaded+ is +false+.
    def each(only_loaded: false)
      return to_enum(__method__, only_loaded: only_loaded) unless block_given?

      if @all_objects_loaded || only_loaded
        @objects.each {|_oid, _gen, data| yield(data) }
      else
        seen = {}
        @objects.each {|oid, _gen, data| seen[oid] = true; yield(data) }
        @xref_section.each do |oid, _gen, data|
          yield(@objects[oid] || load_object(data)) unless seen.key?(oid)
        end
        @all_objects_loaded = true
      end

      self
    end

    # :call-seq:
    #   revision.each_modified_object(delete: false, all: all) {|obj| block }   -> revision
    #   revision.each_modified_object(delete: false, all: all)                  -> Enumerator
    #
    # Calls the given block once for each object that has been modified since it was loaded. Added
    # or eleted object and cross-reference streams as well as signature dictionaries are ignored.
    #
    # +delete+:: If the +delete+ argument is set to +true+, each modified object is deleted from the
    #            active objects.
    #
    # +all+:: If the +all+ argument is set to +true+, added object and cross-reference streams are
    #         also yielded.
    #
    # Note that this also means that for revisions without an associated cross-reference section all
    # loaded objects will be yielded.
    def each_modified_object(delete: false, all: false)
      return to_enum(__method__, delete: delete, all: all) unless block_given?

      @objects.each do |oid, gen, obj|
        if @xref_section.entry?(oid, gen)
          stored_obj = @loader.call(@xref_section[oid, gen])
          next if (stored_obj.type == :ObjStm || stored_obj.type == :XRef) && obj.null? ||
            stored_obj.type == :Sig || stored_obj.type == :DocTimeStamp

          streams_are_same = (obj.data.stream == stored_obj.data.stream)
          next if obj.value == stored_obj.value && streams_are_same

          if obj.value.kind_of?(Hash) && stored_obj.value.kind_of?(Hash)
            keys = obj.value.keys | stored_obj.value.keys
            values_unchanged = keys.all? do |key|
              other = stored_obj[key]
              # Force comparison of values if both are indirect objects
              other = other.value if other.kind_of?(Object) && !other.indirect?
              obj[key] == other
            end
            next if values_unchanged && streams_are_same
          end
        elsif !all && (obj.type == :XRef || obj.type == :ObjStm)
          next
        end

        yield(obj)
        @objects.delete(oid) if delete
      end

      self
    end

    private

    # Loads a single object from the associated cross-reference section.
    def load_object(xref_entry)
      add_without_check(@loader.call(xref_entry))
    end

    # Adds the object to the available objects of this revision and returns it.
    def add_without_check(obj)
      @objects[obj.oid, obj.gen] = obj
    end

  end

end
