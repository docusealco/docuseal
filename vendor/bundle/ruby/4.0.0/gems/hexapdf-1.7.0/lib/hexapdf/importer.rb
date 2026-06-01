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
require 'weakref'

module HexaPDF

  # The Importer class manages the process of copying objects from one Document to another.
  #
  # It may seem unnecessary using an importer containing state for the task. However, by retaining
  # some information about the already copied objects we can make sure that already imported
  # objects don't get imported again.
  #
  # Two types of indirect objects are *never* imported from one document to another: the catalog
  # and page tree nodes. If the catalog was imported, the whole source document would be imported.
  # And if one page tree node would imported, the whole page tree would be imported.
  #
  # See: Document#import
  class Importer

    class NullableWeakRef < WeakRef #:nodoc:

      def __getobj__ #:nodoc:
        super rescue nil
      end

    end

    # Returns the Importer object for copying objects to the +destination+ document.
    def self.for(destination)
      @map ||= {}
      @map.keep_if {|_, v| v.destination.weakref_alive? }
      destination = NullableWeakRef.new(destination)
      @map[destination.hash] ||= new(destination)
    end

    # Imports the given +object+ (belonging to the +source+ document) by completely copying it and
    # all referenced objects into the +destination+ object.
    #
    # If the +allow_all+ argument is set to +true+, then the usually omitted catalog and page tree
    # node objects (see the class description for details) are also copied which allows one to make
    # an in-memory duplicate of a HexaPDF::Document object.
    #
    # Specifying +source+ is optionial if it can be determined through +object+.
    #
    # After the operation is finished, all state is discarded. This means that another call to this
    # method for the same object will yield a new - and different - object. This is in contrast to
    # using ::for together with #import which remembers and returns already imported objects (which
    # is generally what one wants).
    def self.copy(destination, object, allow_all: false, source: nil)
      new(NullableWeakRef.new(destination), allow_all: allow_all).import(object, source: source)
    end

    private_class_method :new

    attr_reader :destination #:nodoc:

    # Initializes a new importer that can import objects to the +destination+ document.
    def initialize(destination, allow_all: false)
      @destination = destination
      @mapper = {}
      @allow_all = allow_all
    end

    SourceWrapper = Struct.new(:source) #:nodoc:

    # Imports the given +object+ to the destination object and returns the imported object.
    #
    # Note: Indirect objects are automatically added to the destination document but direct or
    # simple objects are not.
    #
    # The +source+ argument should be +nil+ or set to the source document of the imported object. If
    # it is +nil+, the source document is dynamically identified. If this identification is not
    # possible and the source document would be needed, an error is raised.
    def import(object, source: nil)
      internal_import(object, SourceWrapper.new(source))
    end

    private

    # Does the actual importing of the given +object+, using +wrapper+ to store/use the source
    # document.
    def internal_import(object, wrapper)
      mapped_object = @mapper[object.data]&.__getobj__ if object.kind_of?(HexaPDF::Object)
      if mapped_object && !mapped_object.null?
        if object.class != mapped_object.class
          mapped_object = @destination.wrap(mapped_object, type: object.class)
        end
        mapped_object
      else
        duplicate(object, wrapper)
      end
    end

    # Recursively duplicates the object.
    #
    # PDF objects are automatically added to the destination document if they are indirect objects
    # in the source document.
    def duplicate(object, wrapper)
      case object
      when Hash
        object.transform_values {|v| duplicate(v, wrapper) }
      when Array
        object.map {|v| duplicate(v, wrapper) }
      when HexaPDF::Reference
        raise HexaPDF::Error, "Import error: No source document specified" unless wrapper.source
        internal_import(wrapper.source.object(object), wrapper)
      when HexaPDF::Object
        wrapper.source ||= object.document
        if object.null? || (!@allow_all && (object.type == :Catalog || object.type == :Pages))
          @mapper[object.data] = nil
        elsif (mapped_object = @mapper[object.data]&.__getobj__) && !mapped_object.null?
          mapped_object
        else
          obj = object.dup
          @mapper[object.data] = NullableWeakRef.new(obj)
          obj.document = @destination.__getobj__
          obj.instance_variable_set(:@data, obj.data.dup)
          obj.data.oid = 0
          obj.data.gen = 0
          @destination.add(obj) if object.indirect?

          stream = obj.data.stream
          if stream.kind_of?(String)
            obj.data.stream = stream.dup
          elsif stream&.source.kind_of?(FiberDoubleForString)
            obj.data.stream = stream.fiber.resume.dup
          end
          obj.data.value = duplicate(obj.data.value, wrapper)
          obj.data.value.update(duplicate(object.copy_inherited_values, wrapper)) if object.type == :Page
          obj
        end
      when String
        object.dup
      else
        object
      end
    end

  end

end
