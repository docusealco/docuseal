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

require 'hexapdf/type/actions'
require 'hexapdf/type/annotations'

module HexaPDF

  # == Overview
  #
  # The Type module contains implementations of the types defined in the PDF specification.
  #
  # Each type class is derived from either the Dictionary class or the Stream class, depending on
  # whether the type has an associated stream.
  module Type

    autoload(:XRefStream, 'hexapdf/type/xref_stream')
    autoload(:ObjectStream, 'hexapdf/type/object_stream')
    autoload(:Trailer, 'hexapdf/type/trailer')
    autoload(:Info, 'hexapdf/type/info')
    autoload(:Catalog, 'hexapdf/type/catalog')
    autoload(:ViewerPreferences, 'hexapdf/type/viewer_preferences')
    autoload(:PageTreeNode, 'hexapdf/type/page_tree_node')
    autoload(:Page, 'hexapdf/type/page')
    autoload(:Names, 'hexapdf/type/names')
    autoload(:FileSpecification, 'hexapdf/type/file_specification')
    autoload(:EmbeddedFile, 'hexapdf/type/embedded_file')
    autoload(:Resources, 'hexapdf/type/resources')
    autoload(:GraphicsStateParameter, 'hexapdf/type/graphics_state_parameter')
    autoload(:Image, 'hexapdf/type/image')
    autoload(:Form, 'hexapdf/type/form')
    autoload(:Font, 'hexapdf/type/font')
    autoload(:FontDescriptor, 'hexapdf/type/font_descriptor')
    autoload(:FontSimple, 'hexapdf/type/font_simple')
    autoload(:FontType1, 'hexapdf/type/font_type1')
    autoload(:FontTrueType, 'hexapdf/type/font_true_type')
    autoload(:FontType0, 'hexapdf/type/font_type0')
    autoload(:CIDFont, 'hexapdf/type/cid_font')
    autoload(:FontType3, 'hexapdf/type/font_type3')
    autoload(:IconFit, 'hexapdf/type/icon_fit')
    autoload(:AcroForm, 'hexapdf/type/acro_form')
    autoload(:Outline, 'hexapdf/type/outline')
    autoload(:OutlineItem, 'hexapdf/type/outline_item')
    autoload(:PageLabel, 'hexapdf/type/page_label')
    autoload(:MarkInformation, 'hexapdf/type/mark_information')
    autoload(:OptionalContentGroup, 'hexapdf/type/optional_content_group')
    autoload(:OptionalContentMembership, 'hexapdf/type/optional_content_membership')
    autoload(:OptionalContentProperties, 'hexapdf/type/optional_content_properties')
    autoload(:OptionalContentConfiguration, 'hexapdf/type/optional_content_configuration')
    autoload(:Metadata, 'hexapdf/type/metadata')
    autoload(:OutputIntent, 'hexapdf/type/output_intent')
    autoload(:CMap, 'hexapdf/type/cmap')
    autoload(:StructTreeRoot, 'hexapdf/type/struct_tree_root')
    autoload(:StructElem, 'hexapdf/type/struct_elem')
    autoload(:Namespace, 'hexapdf/type/namespace')
    autoload(:MarkedContentReference, 'hexapdf/type/marked_content_reference')
    autoload(:ObjectReference, 'hexapdf/type/object_reference')
    autoload(:Measure, 'hexapdf/type/measure')
    autoload(:DocumentSecurityStore, 'hexapdf/type/document_security_store')

  end

end
