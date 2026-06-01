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

require 'hexapdf/dictionary'

module HexaPDF
  module Type

    # Represents the PDF's viewer preferences dictionary which defines how a document should be
    # presented on screen or in print.
    #
    # This dictionary is linked via the /ViewerPreferences entry from the Type::Catalog.
    #
    # See: PDF2.0 s12.2, Catalog
    class ViewerPreferences < Dictionary

      define_type :XXViewerPreferences

      define_field :HideToolbar,           type: Boolean, default: false
      define_field :HideMenubar,           type: Boolean, default: false
      define_field :HideWindowUI,          type: Boolean, default: false
      define_field :FitWindow,             type: Boolean, default: false
      define_field :CenterWindow,          type: Boolean, default: false
      define_field :DisplayDocTitle,       type: Boolean, default: false, version: '1.4'
      define_field :NonFullScreenPageMode, type: Symbol,  default: :UseNone,
                   allowed_values: [:UseNone, :UseOutlines, :UseThumbs, :UseOC]
      define_field :Direction,             type: Symbol,  default: :L2R, version: '1.3',
                   allowed_values: [:L2R, :R2L]
      define_field :ViewArea,              type: Symbol,  default: :CropBox, version: '1.4'
      define_field :ViewClip,              type: Symbol,  default: :CropBox, version: '1.4'
      define_field :PrintArea,             type: Symbol,  default: :CropBox, version: '1.4'
      define_field :PrintClip,             type: Symbol,  default: :CropBox, version: '1.4'
      define_field :PrintScaling,          type: Symbol,  default: :AppDefault, version: '1.6'
      define_field :Duplex,                type: Symbol,  version: '1.7',
                   allowed_values: [:Simplex, :DuplexFlipShortEdge, :DuplexFlipLongEdge]
      define_field :PickTrayByPDFSize,     type: Boolean, version: '1.7'
      define_field :PrintPageRange,        type: PDFArray, version: '1.7'
      define_field :NumCopies,             type: Integer, version: '1.7'
      define_field :Enforce,               type: PDFArray, version: '2.0'

    end

  end
end
