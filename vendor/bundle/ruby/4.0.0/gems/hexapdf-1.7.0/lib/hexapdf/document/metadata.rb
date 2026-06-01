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

require 'securerandom'
require 'hexapdf/dictionary'
require 'hexapdf/error'

module HexaPDF
  class Document

    # This class provides methods for reading and writing the document-level metadata.
    #
    # When an instance is created (usually through HexaPDF::Document#metadata), the metadata is read
    # from the document's information dictionary (see HexaPDF::Type::Info) and made available
    # through the various methods.
    #
    # By default, the metadata is written to the information dictionary as well as to the document's
    # metadata stream (see HexaPDF::Type::Metadata) once the document is written. This can be
    # controlled via the #write_info_dict and #write_metdata_stream methods.
    #
    # While HexaPDF is able to write an XMP packet (using a limited form) to the document's metadata
    # stream, it provides no way for reading XMP metadata. If reading functionality or extended
    # writing functionality is needed, make sure this class does not write the metadata and
    # read/create the metadata stream yourself.
    #
    #
    # == Caveats
    #
    # * Disabling writing to the information dictionary will only prevent parts from being written.
    #   The #producer is always written to the information dictionary as per the AGPL license terms.
    #   The #modification_date may be written depending on the arguments to HexaPDF::Document#write.
    #
    # * If writing the metadata stream is enabled, any existing metadata stream is completely
    #   overwritten. This means the metadata stream is *not* updated with the changed information.
    #
    #
    # == Adding custom metadata properties
    #
    # All the properties specified for the information dictionary are supported.
    #
    # Furthermore, HexaPDF supports writing custom properties to the metadata stream. For this to
    # work the used XMP namespaces need to be registered using #register_namespace. Additionally,
    # the types of all used XMP properties need to be registered using #register_property.
    #
    # The following types for XMP properties are supported:
    #
    # String::
    #     Maps to the XMP simple string value. Values need to be of type String.
    #
    # Integer::
    #     Maps to the XMP integer core value type and gets formatted as string. Values need to be of
    #     type Integer.
    #
    # Date::
    #     Maps to the XMP simple string value, correctly formatted. Values need to be of type Time,
    #     Date, or DateTime
    #
    # URI::
    #     Maps to the XMP simple value variant of URI. Values need to be of type String or URI.
    #
    # Boolean::
    #     Maps to the XMP simple string value, correctly formatted. Values need to be either +true+
    #     or +false+.
    #
    # OrderedArray::
    #     Maps to the XMP ordered array. Values need to be of type Array and items must be XMP
    #     simple values.
    #
    # UnorderedArray::
    #     Maps to the XMP unordered array. Values need to be of type Array and items must be
    #     simple values.
    #
    # LanguageArray
    #     Maps to the XMP language alternatives array. Values need to be of type Array and items
    #     must either be strings (they are associated with the set default language) or
    #     LocalizedString instances.
    #
    #
    # See: PDF2.0 s14.3, https://www.adobe.com/products/xmp.html
    class Metadata

      # Represents a localized XMP string, i.e. as string with an attached language.
      class LocalizedString < String

        # The language identifier for the string in RFC3066 format.
        attr_accessor :language

      end

      # Contains a mapping of predefined prefixes for XMP namespaces for metadata.
      PREDEFINED_NAMESPACES = {
        "rdf" => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
        "xmp" => "http://ns.adobe.com/xap/1.0/",
        "pdf" => "http://ns.adobe.com/pdf/1.3/",
        "dc" => "http://purl.org/dc/elements/1.1/",
        "x" => "adobe:ns:meta/",
        "pdfaid" => "http://www.aiim.org/pdfa/ns/id/",
      }.freeze

      # Contains a mapping of predefined XMP properties to their types, i.e. from namespace to
      # property and then type.
      PREDEFINED_PROPERTIES = {
        "http://ns.adobe.com/xap/1.0/" => {
          'CreatorTool' => 'String',
          'CreateDate' => 'Date',
          'ModifyDate' => 'Date',
        }.freeze,
        "http://ns.adobe.com/pdf/1.3/" => {
          'Keywords' => 'String',
          'Producer' => 'String',
          'Trapped' => 'Boolean',
        }.freeze,
        "http://purl.org/dc/elements/1.1/" => {
          'creator' => 'OrderedArray',
          'description' => 'LanguageArray',
          'title' => 'LanguageArray',
        }.freeze,
        "http://www.aiim.org/pdfa/ns/id/" => {
          'part' => 'Integer',
          'conformance' => 'String',
        }.freeze,
      }.freeze

      # Creates a new Metadata object for the given PDF document.
      def initialize(document)
        @document = document
        @namespaces = PREDEFINED_NAMESPACES.dup
        @properties = PREDEFINED_PROPERTIES.transform_values(&:dup)
        @default_language = document.catalog[:Lang] || 'x-default'
        @metadata = Hash.new {|h, k| h[k] = {} }
        @custom_metadata = []
        write_info_dict(true)
        write_metadata_stream(true)
        @document.register_listener(:complete_objects, &method(:write_metadata))
        parse_metadata
      end

      # :call-seq:
      #   metadata.default_language          -> language
      #   metadata.default_language(value)   -> value
      #
      # Returns the default language in RFC3066 format used for unlocalized strings if no argument
      # is given. Otherwise sets the default language to the given language.
      #
      # The initial default lanuage is taken from the document catalog's /Lang entry. If that is not
      # set, the default language is assumed to be default language ('x-default').
      def default_language(value = :UNSET)
        if value == :UNSET
          @default_language
        else
          @default_language = value
        end
      end

      # Returns +true+ if the information dictionary should be written.
      def write_info_dict?
        @write_info_dict
      end

      # Makes HexaPDF write the information dictionary if +value+ is +true+.
      #
      # See the class documentation for caveats.
      def write_info_dict(value)
        @write_info_dict = value
      end

      # Returns +true+ if the metadata stream should be written.
      def write_metadata_stream?
        @write_metadata_stream
      end

      # Makes HexaPDF write the metadata stream if +value+ is +true+.
      #
      # See the class documentation for caveats.
      def write_metadata_stream(value)
        @write_metadata_stream = value
      end

      # Registers the +prefix+ for the given namespace +uri+.
      def register_namespace(prefix, uri)
        @namespaces[prefix] = uri
      end

      # Returns the namespace URI associated with the given prefix.
      def namespace(ns)
        @namespaces.fetch(ns) do
          raise HexaPDF::Error, "Namespace prefix '#{ns}' not registered"
        end
      end

      # Registers the +property+ for the namespace specified via +prefix+ as the given +type+.
      #
      # The argument +type+ has to be one of the following: 'String', 'Integer', 'Date', 'URI',
      # 'Boolean', 'OrderedArray', 'UnorderedArray', or 'LanguageArray'.
      def register_property_type(prefix, property, type)
        (@properties[namespace(prefix)] ||= {})[property] = type
      end

      # :call-seq:
      #   metadata.property(ns_prefix, name)           -> property_value
      #   metadata.property(ns_prefix, name, value)    -> value
      #
      # Returns the value for the property specified via the namespace prefix +ns_prefix+ and +name+
      # if the +value+ argument is not provided. Otherwise sets the property to +value+.
      #
      # The value +nil+ is returned if the property ist not set. And by using +nil+ as +value+ the
      # property is deleted from the metadata.
      def property(ns, property, value = :UNSET)
        ns = @metadata[namespace(ns)]
        if value == :UNSET
          ns[property]
        elsif value.nil?
          ns.delete(property)
        else
          ns[property] = value
        end
      end

      # Adds the given +data+ string as custom metadata to the XMP document.
      #
      # The +data+ string must contain a fully valid 'rdf:Description' element.
      #
      # Using this method allows adding metadata like PDF/A schema definitions for which there is no
      # direct support by HexaPDF.
      def custom_metadata(data)
        @custom_metadata << data
      end

      # :call-seq:
      #   metadata.delete
      #   metadata.delete(ns_prefix)
      #   metadata.delete(ns_prefix, name)
      #
      # Deletes either all metadata properties, only the ones from a specific namespace, or a
      # specific one.
      def delete(ns = nil, property = nil)
        if ns.nil? && property.nil?
          @metadata.clear
        elsif property.nil?
          @metadata.delete(namespace(ns))
        else
          @metadata[namespace(ns)].delete(property)
        end
      end

      # :call-seq:
      #   metadata.title           -> title or nil
      #   metadata.title(value)    -> value
      #
      # Returns the document's title if no argument is given. Otherwise sets the document's title to
      # the given value.
      #
      # If the +value+ is a LocalizedString, the language for the title is taken from it. Otherwise
      # the language specified via #default_language is used.
      #
      # The value +nil+ is returned if the property is not set. And by using +nil+ as +value+ the
      # property is deleted from the metadata.
      #
      # This metadata property is represented by the XMP name dc:title.
      def title(value = :UNSET)
        property('dc', 'title', value)
      end

      # :call-seq:
      #   metadata.author           -> author or nil
      #   metadata.author(value)    -> value
      #
      # Returns the name of the person who created the document (author) if no argument is given.
      # Otherwise sets the author to the given value.
      #
      # The value +nil+ is returned if the property ist not set. And by using +nil+ as +value+ the
      # property is deleted from the metadata.
      #
      # This metadata property is represented by the XMP name dc:creator.
      def author(value = :UNSET)
        property('dc', 'creator', value)
      end

      # :call-seq:
      #   metadata.subject           -> subject or nil
      #   metadata.subject(value)    -> value
      #
      # Returns the subject of the document if no argument is given. Otherwise sets the subject to
      # the given value.
      #
      # If the +value+ is a LocalizedString, the language for the subject is taken from it.
      # Otherwise the language specified via #default_language is used.
      #
      # The value +nil+ is returned if the property ist not set. And by using +nil+ as +value+ the
      # property is deleted from the metadata.
      #
      # This metadata property is represented by the XMP name dc:description.
      def subject(value = :UNSET)
        property('dc', 'description', value)
      end

      # :call-seq:
      #   metadata.keywords           -> keywords or nil
      #   metadata.keywords(value)    -> value
      #
      # Returns the keywords associated with the document if no argument is given. Otherwise sets
      # keywords to the given value.
      #
      # The value +nil+ is returned if the property ist not set. And by using +nil+ as +value+ the
      # property is deleted from the metadata.
      #
      # This metadata property is represented by the XMP name pdf:Keywords.
      def keywords(value = :UNSET)
        property('pdf', 'Keywords', value)
      end

      # :call-seq:
      #   metadata.creator           -> creator or nil
      #   metadata.creator(value)    -> value
      #
      # Returns the name of the PDF processor that created the original document from which this PDF
      # was converted if no argument is given. Otherwise sets the name of the creator tool to the
      # given value.
      #
      # The value +nil+ is returned if the property ist not set. And by using +nil+ as +value+ the
      # property is deleted from the metadata.
      #
      # This metadata property is represented by the XMP name xmp:CreatorTool.
      def creator(value = :UNSET)
        property('xmp', 'CreatorTool', value)
      end

      # :call-seq:
      #   metadata.producer           -> producer or nil
      #   metadata.producer(value)    -> value
      #
      # Returns the name of the PDF processor that converted the original document to PDF if no
      # argument is given. Otherwise sets the name of the producer to the given value.
      #
      # The value +nil+ is returned if the property ist not set. And by using +nil+ as +value+ the
      # property is deleted from the metadata.
      #
      # This metadata property is represented by the XMP name pdf:Producer.
      def producer(value = :UNSET)
        property('pdf', 'Producer', value)
      end

      # :call-seq:
      #   metadata.creation_date           -> creation_date or nil
      #   metadata.creation_date(value)    -> value
      #
      # Returns the date and time (a Time object) the document was created if no argument is given.
      # Otherwise sets the creation date to the given value.
      #
      # The value +nil+ is returned if the property ist not set. And by using +nil+ as +value+ the
      # property is deleted from the metadata.
      #
      # This metadata property is represented by the XMP name xmp:CreateDate.
      def creation_date(value = :UNSET)
        property('xmp', 'CreateDate', value)
      end

      # :call-seq:
      #   metadata.modification_date           -> modification_date or nil
      #   metadata.modification_date(value)    -> value
      #
      # Returns the date and time (a Time object) the document was most recently modified if no
      # argument is given. Otherwise sets the modification date to the given value.
      #
      # The value +nil+ is returned if the property ist not set. And by using +nil+ as +value+ the
      # property is deleted from the metadata.
      #
      # This metadata property is represented by the XMP name xmp:ModifyDate.
      def modification_date(value = :UNSET)
        property('xmp', 'ModifyDate', value)
      end

      # :call-seq:
      #   metadata.trapped           -> trapped or nil
      #   metadata.trapped(value)    -> value
      #
      # Returns +true+ if the document has been modified to include trapping information if no
      # argument is given. Otherwise sets the trapped status to the given boolean value.
      #
      # The value +nil+ is returned if the property ist not set. And by using +nil+ as +value+ the
      # property is deleted from the metadata.
      #
      # This metadata property is represented by the XMP name pdf:Trapped.
      def trapped(value = :UNSET)
        property('pdf', 'Trapped', value)
      end

      private

      # Parses the metadata from the information dictionary into the internal data structure.
      def parse_metadata
        info_dict = @document.trailer.info
        ns_dc = namespace('dc')
        ns_xmp = namespace('xmp')
        ns_pdf = namespace('pdf')
        @metadata[ns_dc]['title'] = info_dict[:Title] if info_dict.key?(:Title)
        @metadata[ns_dc]['creator'] = info_dict[:Author] if info_dict.key?(:Author)
        @metadata[ns_dc]['description'] = info_dict[:Subject] if info_dict.key?(:Subject)
        @metadata[ns_xmp]['CreatorTool'] = info_dict[:Creator] if info_dict.key?(:Creator)
        if info_dict.key?(:CreationDate) && !info_dict[:CreationDate].kind_of?(String)
          @metadata[ns_xmp]['CreateDate'] = info_dict[:CreationDate]
        end
        if info_dict.key?(:ModDate) && !info_dict[:ModDate].kind_of?(String)
          @metadata[ns_xmp]['ModifyDate'] = info_dict[:ModDate] if info_dict.key?(:ModDate)
        end
        @metadata[ns_pdf]['Keywords'] = info_dict[:Keywords] if info_dict.key?(:Keywords)
        @metadata[ns_pdf]['Producer'] = info_dict[:Producer] if info_dict.key?(:Producer)
        if info_dict.key?(:Trapped) && info_dict[:Trapped] != :Unknown
          @metadata[ns_pdf]['Trapped'] = (info_dict[:Trapped] == :True)
        end
      end

      # Writes the metadata to the specified destinations.
      def write_metadata
        ns_dc = namespace('dc')
        ns_xmp = namespace('xmp')
        ns_pdf = namespace('pdf')

        producer("HexaPDF version #{HexaPDF::VERSION}")

        if write_info_dict?
          info_dict = @document.trailer.info
          info_dict[:Title] = Array(@metadata[ns_dc]['title']).first
          if @metadata[ns_dc].key?('creator')
            info_dict[:Author] = Array(@metadata[ns_dc]['creator']).join(', ')
          end
          info_dict[:Subject] = Array(@metadata[ns_dc]['description']).first
          info_dict[:Creator] = @metadata[ns_xmp]['CreatorTool']
          info_dict[:CreationDate] = @metadata[ns_xmp]['CreateDate']
          info_dict[:ModDate] = @metadata[ns_xmp]['ModifyDate']
          info_dict[:Keywords] = @metadata[ns_pdf]['Keywords']
          info_dict[:Producer] = @metadata[ns_pdf]['Producer']
          if @metadata[ns_pdf].key?('Trapped')
            info_dict[:Trapped] = @metadata[ns_pdf]['Trapped'] ? :True : :False
          end
        end

        if write_metadata_stream?
          descriptions = @metadata.map do |namespace, values|
            next if values.empty?
            xmp_description(@namespaces.key(namespace), values)
          end.compact.join("\n")
          obj = @document.catalog[:Metadata] ||= @document.add({Type: :Metadata, Subtype: :XML})
          obj.stream = xmp_packet(descriptions)
        end
      end

      # Creates an XMP packet with the given payload +data+.
      def xmp_packet(data)
        <<~XMP
          <?xpacket begin="\u{FEFF}" id="#{SecureRandom.uuid.tr('-', '')}"?>
          <x:xmpmeta xmlns:x="adobe:ns:meta/">
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
          #{data}#{@custom_metadata.empty? ? '' : "\n#{@custom_metadata.join("\n")}"}
          </rdf:RDF>
          </x:xmpmeta>
          <?xpacket end="r"?>
        XMP
      end

      # Creates an 'rdf:Description' element for all metadata +values+ with the given +ns_prefix+.
      def xmp_description(ns_prefix, values)
        values = values.map do |name, value|
          str = +"<#{ns_prefix}:#{name}"
          case (property_type = @properties[namespace(ns_prefix)][name])
          when 'String', 'Integer'
            str << ">#{xmp_escape(value.to_s)}</#{ns_prefix}:#{name}>"
          when 'Date'
            str << ">#{xmp_date(value)}</#{ns_prefix}:#{name}>"
          when 'URI'
            str << " rdf:resource=\"#{xmp_escape(value.to_s)}\" />"
          when 'Boolean'
            str << ">#{value ? 'True' : 'False'}</#{ns_prefix}:#{name}>"
          when 'LanguageArray'
            value = Array(value).map do |item|
              lang = item.respond_to?(:language) ? item.language : default_language
              "<rdf:li xml:lang=\"#{lang}\">#{xmp_escape(item)}</rdf:li>"
            end.join("\n")
            str << "><rdf:Alt>\n#{value}\n</rdf:Alt></#{ns_prefix}:#{name}>"
          when 'OrderedArray', 'UnorderedArray'
            value = Array(value).map {|item| "<rdf:li>#{xmp_escape(item)}</rdf:li>" }.join("\n")
            el_type = (property_type == 'OrderedArray' ? 'Seq' : 'Bag')
            str << "><rdf:#{el_type}>\n#{value}\n</rdf:#{el_type}></#{ns_prefix}:#{name}>"
          end
          str
        end.join("\n")
        <<~XMP.strip
          <rdf:Description rdf:about="" xmlns:#{ns_prefix}="#{xmp_escape(namespace(ns_prefix))}">
          #{values}
          </rdf:Description>
        XMP
      end

      # Escapes the given value so as to be usable as XMP simple value.
      def xmp_escape(value)
        value.gsub(/<|>|"/, {'<' => '&lt;', '>' => '&gt;', '"' => '&quot;'})
      end

      # Formats the given date-time object (Time, Date, or DateTime) to be a valid XMP date-time
      # value.
      def xmp_date(date)
        case date
        when Time, Date, DateTime then date.strftime("%Y-%m-%dT%H:%M:%S%:z")
        else ''
        end
      end

    end

  end
end
