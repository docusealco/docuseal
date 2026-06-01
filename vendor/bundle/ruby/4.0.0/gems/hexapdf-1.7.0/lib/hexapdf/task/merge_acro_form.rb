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

require 'hexapdf/serializer'

module HexaPDF
  module Task

    # Task for merging an AcroForm from one PDF into another.
    #
    # It takes care of
    #
    # * adding the fields to the main Type::AcroForm::Form dictionary,
    # * adjusting the field names so that they are unique,
    # * and merging the properties of the main AcroForm dictionary itself and adjusting field
    #   information appropriately.
    #
    # Note that the pages with the fields need to be imported already.
    #
    # The steps for using this task are:
    #
    # 1. Import the pages into the target document and add all imported pages to an array
    # 2. Call this task using the created array of pages.
    #
    # Example:
    #
    #   pages = doc.pages.map {|page| target.pages.add(target.import(page)) }
    #   target.task(:merge_acro_form, source: doc, pages: pages)
    module MergeAcroForm

      # Performs the necessary steps to merge the AcroForm fields from the +source+ into the target
      # document +doc+.
      #
      # +source+::
      #     Specifies the source PDF document the information from which should be merged into the
      #     target document.
      #
      # +pages+::
      #     An array of pages that were imported from +source+ and contain the widgets of the fields
      #     that should be merged.
      def self.call(doc, source:, pages:)
        return unless source.acro_form

        acro_form = doc.acro_form(create: true)

        # Determine a unique name for root field and create root field
        import_name = 'merged_' +
                      (acro_form.root_fields.select {|field| field[:T] =~ /\Amerged_\d+\z/ }.
                        map {|field| field[:T][/\d+/].to_i }.sort.last || 0).succ.to_s
        root_field = doc.add({T: import_name, Kids: []})
        acro_form.root_fields << root_field

        # Merge the main AcroForm dictionary
        font_name_mapping = merge_form_dictionary(acro_form, source.acro_form, root_field)
        font_name_re = font_name_mapping.keys.map {|name| Regexp.escape(name) }.join('|')
        root_field[:DA] && root_field[:DA].sub!(font_name_re, font_name_mapping)

        # Process all field widgets of the given pages
        process_calculate_actions = false
        signature_field_seen = false
        pages.each do |page|
          page.each_annotation do |widget|
            next unless widget[:Subtype] == :Widget
            field = widget.form_field

            # Correct the font name in the default appearance string
            widget[:DA] && widget[:DA].sub!(font_name_re, font_name_mapping)
            field[:DA] && field[:DA].sub!(font_name_re, font_name_mapping)

            process_calculate_actions = true if field[:AA]&.[](:C)
            signature_field_seen = true if field.field_type == :Sig

            # Add to the root field
            field = field[:Parent] while field[:Parent]
            if field != root_field
              field[:Parent] = root_field
              root_field[:Kids] << field
            end
          end
        end

        # Update calculation JavaScript actions with changed field names
        fix_calculate_actions(acro_form, source.acro_form, import_name) if process_calculate_actions

        # Update signature flags if necessary
        if signature_field_seen && source.acro_form.signature_flag?(:signatures_exist)
          acro_form.signature_flag(:signatures_exist)
        end
      end

      # Merges the AcroForm +source_form+ into the +target_form+ and returns a mapping of old font
      # names to new ones.
      def self.merge_form_dictionary(target_form, source_form, root_field)
        target_resources = target_form.default_resources
        font_name_mapping = {}
        serializer = HexaPDF::Serializer.new

        source_form.default_resources[:Font].each do |font_name, value|
          new_name = target_resources.add_font(target_form.document.import(value))
          font_name_mapping[serializer.serialize(font_name)] = serializer.serialize(new_name)
        end

        root_field[:DA] = target_form.document.import(source_form[:DA])
        root_field[:Q] = target_form.document.import(source_form[:Q])

        font_name_mapping
      end

      # Fixes the calculate actions listed in the /CO entry of the main AcroForm dictionary to use
      # the new names of the fields.
      def self.fix_calculate_actions(acro_form, source_form, import_name)
        if source_form[:CO]
          acro_form[:CO] ||= []
          acro_form[:CO].value.concat(acro_form.document.import(source_form[:CO]).value)
          acro_form[:CO].each do |field|
            next unless (action = field[:AA]&.[](:C))
            action[:JS].gsub!(/"(.*?)"/) do |match|
              if source_form.field_by_name($1)
                "\"#{import_name}.#{$1}\""
              else
                match
              end
            end
          end
        end
      end

    end

  end
end
