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

require 'set'
require 'stringio'
require 'hexapdf/error'
require 'hexapdf/stream'
require 'hexapdf/reference'
require 'hexapdf/tokenizer'
require 'hexapdf/serializer'

module HexaPDF
  module Type

    # Represents PDF type ObjStm, object streams.
    #
    # An object stream is a stream that can hold multiple indirect objects. Since the objects are
    # stored inside the stream, filters can be used to compress the stream content and therefore
    # represent the indirect objects more compactly than would be possible otherwise.
    #
    # == How are Object Streams Used?
    #
    # When an indirect object that resides in an object stream needs to be loaded, the object stream
    # itself is parsed and loaded and #parse_stream is invoked to get an ObjectStream::Data object
    # representing the stored indirect objects. After that the requested indirect object itself is
    # loaded and returned using this ObjectStream::Data object. From a user's perspective nothing
    # changes when an object is located inside an object stream instead of directly in a PDF file.
    #
    # The indirect objects initially stored in the object stream are automatically added to the
    # list of to-be-stored objects when #parse_stream is invoked. Additional objects can be
    # assigned to the object stream via #add_object or deleted from it via #delete_object.
    #
    # Before an object stream is written, it is necessary to invoke #write_objects so that the
    # to-be-stored objects are serialized to the stream. This is automatically done by the Writer.
    # A user thus only has to define which objects should reside in the object stream.
    #
    # However, only objects that can be written to the object stream are actually written. The
    # other objects are deleted from the object stream (#delete_object) and written normally.
    #
    # See PDF2.0 s7.5.7
    class ObjectStream < HexaPDF::Stream

      # Holds all necessary information to load objects for an object stream.
      class Data

        # Initializes the data object with the needed values.
        def initialize(stream_data, oids, offsets)
          @tokenizer = Tokenizer.new(StringIO.new(stream_data))
          @offsets = offsets
          @oids = oids
        end

        # Returns the object specified by the given index together with its object number.
        #
        # Objects are not pre-loaded, so every time this method is invoked the associated stream
        # data is parsed and a new object returned.
        def object_by_index(index)
          if index >= @offsets.size || index < 0
            raise ArgumentError, "Invalid index into object stream given"
          end

          @tokenizer.pos = @offsets[index]
          [@tokenizer.next_object, @oids[index]]
        end

      end

      define_type :ObjStm

      define_field :Type,    type: Symbol, required: true, default: type, version: '1.5'
      define_field :N,       type: Integer, required: true
      define_field :First,   type: Integer, required: true
      define_field :Extends, type: Stream

      # Parses the stream and returns an ObjectStream::Data object that can be used for retrieving
      # the objects defined by this object stream.
      #
      # The object references are also added to this object stream so that they are included when
      # the object gets written.
      def parse_stream
        return @stream_data if defined?(@stream_data)
        data = stream
        oids, offsets = parse_oids_and_offsets(data)
        @objects ||= {}
        oids.each {|oid| add_object(Reference.new(oid, 0)) }
        @stream_data = Data.new(data, oids, offsets)
      end

      # Adds the given object to the list of objects that should be stored in this object stream.
      #
      # The +ref+ argument can either be a reference or any PDF object.
      def add_object(ref)
        return if object_index(ref)

        index = objects.size / 2
        objects[index] = ref
        objects[ref] = index
      end

      # Deletes the given object from the list of objects that should be stored in this object
      # stream.
      #
      # The +ref+ argument can either be a reference or a PDF object.
      def delete_object(ref)
        index = objects[ref]
        return unless index

        move_index = objects.size / 2 - 1

        objects[index] = objects[move_index]
        objects[objects[index]] = index
        objects.delete(ref)
        objects.delete(move_index)
      end

      # Returns the index into the array containing the to-be-stored objects for the given
      # reference/PDF object.
      def object_index(obj)
        objects[obj]
      end

      # :call-seq:
      #   objstm.write_objects(revision)    -> obj_to_stm_hash
      #
      # Writes the added objects to the stream and returns a hash mapping all written objects to
      # this object stream.
      #
      # There are some reasons why an added object may not be stored in the stream:
      #
      # * It has a generation number other than 0.
      # * It is a stream object.
      # * It doesn't reside in the given Revision object.
      #
      # Such objects are additionally deleted from the list of to-be-stored objects and are later
      # written as indirect objects.
      def write_objects(revision)
        index = 0
        object_info = ''.b
        data = ''.b
        serializer = Serializer.new
        obj_to_stm = {}

        is_encrypt_dict = document.revisions.each.with_object({}) do |rev, hash|
          hash[rev.trailer[:Encrypt]] = true
        end
        while index < objects.size / 2
          obj = revision.object(objects[index])

          # Due to a bug in Adobe Acrobat, the Catalog may not be in an object stream if the
          # document is encrypted
          if obj.nil? || obj.null? || obj.gen != 0 || obj.kind_of?(Stream) ||
              is_encrypt_dict[obj] ||
              obj.type == :Catalog ||
              obj.type == :Sig || obj.type == :DocTimeStamp ||
              (obj.respond_to?(:key?) && obj.key?(:ByteRange) && obj.key?(:Contents))
            delete_object(objects[index])
            next
          end

          obj_to_stm[obj] = self
          object_info << "#{obj.oid} #{data.size} "
          data << serializer.serialize(obj) << " "
          index += 1
        end

        value[:Type] = :ObjStm
        value[:N] = objects.size / 2
        value[:First] = object_info.size
        self.stream = object_info << data
        set_filter(:FlateDecode)

        obj_to_stm
      end

      private

      # Parses the object numbers and their offsets from the start of the stream data.
      def parse_oids_and_offsets(data)
        oids = []
        offsets = []
        first = value[:First].to_i

        stream_tokenizer = Tokenizer.new(StringIO.new(data))
        !data.empty? && value[:N].to_i.times do
          oids << stream_tokenizer.next_object
          offsets << first + stream_tokenizer.next_object
        end

        [oids, offsets]
      end

      # Returns the container with the to-be-stored objects.
      def objects
        @objects ||=
          begin
            @objects = {}
            parse_stream
            @objects
          end
      end

      # Validates that the generation number of the object stream is zero.
      def perform_validation
        # Assign dummy values so that the validation for required values works since those values
        # are only set on #write_objects
        self[:N] ||= 0
        self[:First] ||= 0

        super
        yield("Object stream has invalid generation number > 0", false) if gen != 0
      end

    end

  end
end
