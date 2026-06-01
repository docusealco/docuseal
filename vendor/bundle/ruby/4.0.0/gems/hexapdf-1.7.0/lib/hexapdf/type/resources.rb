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
require 'hexapdf/configuration'
require 'hexapdf/dictionary'
require 'hexapdf/content/color_space'

module HexaPDF
  module Type

    # Represents the resources needed by a content stream.
    #
    # See: PDF2.0 s7.8.3
    class Resources < Dictionary

      define_type :XXResources

      define_field :ExtGState,  type: Dictionary
      define_field :ColorSpace, type: Dictionary
      define_field :Pattern,    type: Dictionary
      define_field :Shading,    type: Dictionary, version: '1.3'
      define_field :XObject,    type: Dictionary
      define_field :Font,       type: Dictionary
      define_field :ProcSet,    type: PDFArray
      define_field :Properties, type: Dictionary, version: '1.2'

      # Returns the color space stored under the given name.
      #
      # If the color space is not found, an error is raised.
      #
      # Note: The color spaces :DeviceGray, :DeviceRGB and :DeviceCMYK are returned without a
      # lookup since they are fixed.
      def color_space(name)
        case name
        when :DeviceRGB, :DeviceGray, :DeviceCMYK
          GlobalConfiguration.constantize('color_space.map', name).new
        else
          space_definition = (name == :Pattern ? name : self[:ColorSpace]&.[](name))
          if space_definition.nil?
            raise HexaPDF::Error, "Color space '#{name}' not found in the resources"
          elsif space_definition.kind_of?(Array)
            space_family = space_definition[0]
          else
            space_family = space_definition
            space_definition = [space_definition]
          end

          GlobalConfiguration.constantize('color_space.map', space_family) do
            HexaPDF::Content::ColorSpace::Universal
          end.new(space_definition)
        end
      end

      # Adds the color space to the resources and returns the name under which it is stored.
      #
      # If there already exists a color space with the same definition, it is reused. The device
      # color spaces +:DeviceGray+, +:DeviceRGB+ and +:DeviceCMYK+ are never stored, their
      # respective name is just returned.
      def add_color_space(color_space)
        family = color_space.family
        return family if family == :DeviceRGB || family == :DeviceGray || family == :DeviceCMYK

        definition = color_space.definition
        self[:ColorSpace] = {} unless key?(:ColorSpace)
        color_space_dict = self[:ColorSpace]

        name, _value = color_space_dict.value.find do |_k, v|
          v.map! {|item| document.deref(item) }
          v == definition
        end
        unless name
          name = create_resource_name(color_space_dict.value, 'CS')
          color_space_dict[name] = definition
        end
        name
      end

      # Returns the XObject stored under the given name.
      #
      # If the XObject is not found, an error is raised.
      def xobject(name)
        object_getter(:XObject, name)
      end

      # Adds the XObject to the resources and returns the name under which it is stored.
      #
      # If there already exists a name for the given XObject, it is just returned.
      def add_xobject(object)
        object_setter(:XObject, 'XO', object)
      end

      # Returns the graphics state parameter dictionary (see Type::GraphicsStateParameter) stored
      # under the given name.
      #
      # If the dictionary is not found, an error is raised.
      def ext_gstate(name)
        object_getter(:ExtGState, name)
      end

      # Adds the graphics state parameter dictionary to the resources and returns the name under
      # which it is stored.
      #
      # If there already exists a name for the given dictionary, it is just returned.
      def add_ext_gstate(object)
        object_setter(:ExtGState, 'GS', object)
      end

      # Returns the font dictionary stored under the given name.
      #
      # If the dictionary is not found, an error is raised.
      def font(name)
        font = object_getter(:Font, name)
        font.kind_of?(Hash) ? document.wrap(font) : font
      end

      # Adds the font dictionary to the resources and returns the name under which it is stored.
      #
      # If there already exists a name for the given dictionary, it is just returned.
      def add_font(object)
        object_setter(:Font, 'F', object)
      end

      # Returns the property list stored under the given name.
      #
      # If the property list is not found, an error is raised.
      def property_list(name)
        object_getter(:Properties, name)
      end

      # Adds the property list to the resources and returns the name under which it is stored.
      #
      # If there already exists a name for the given property list, it is just returned.
      def add_property_list(dict)
        object_setter(:Properties, 'P', dict)
      end

      # Returns the pattern dictionary stored under the given name.
      #
      # If the dictionary is not found, an error is raised.
      def pattern(name)
        object_getter(:Pattern, name)
      end

      # Adds the pattern dictionary to the resources and returns the name under which it is stored.
      #
      # If there already exists a name for the given dictionary, it is just returned.
      def add_pattern(object)
        object_setter(:Pattern, 'P', object)
      end

      private

      # Helper method for returning an entry of a subdictionary.
      def object_getter(dict_name, name)
        obj = self[dict_name] && self[dict_name][name]
        if obj.nil?
          raise HexaPDF::Error, "No object called '#{name}' stored under /#{dict_name}"
        end
        obj
      end

      # Helper method for setting an entry of a subdictionary.
      def object_setter(dict_name, prefix, object)
        self[dict_name] = {} unless key?(dict_name)
        dict = self[dict_name]
        name, _value = dict.each.find {|_, dict_obj| dict_obj == object }
        unless name
          name = create_resource_name(dict.value, prefix)
          dict[name] = object
        end
        name
      end

      # Returns a unique name that can be used to store a resource in the given hash.
      def create_resource_name(hash, prefix)
        n = hash.size + 1
        while true
          name = :"#{prefix}#{n}"
          return name unless hash.key?(name)
          n += 1
        end
      end

      # Ensures that a valid procedure set is available.
      def perform_validation
        val = self[:ProcSet]

        if val.kind_of?(Symbol)
          yield("Procedure set is a single value instead of an Array", true)
          val = value[:ProcSet] = [val]
        end

        super

        return unless val

        val.reject! do |name|
          case name
          when :PDF, :Text, :ImageB, :ImageC, :ImageI
            false
          else
            yield("Invalid page procedure set name /#{name}", true)
            true
          end
        end
      end

    end

  end
end
