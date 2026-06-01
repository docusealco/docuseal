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

require 'hexapdf/type/action'

module HexaPDF
  module Type
    module Actions

      # A Set-OCG-state action changes the state of one or more optional content groups.
      #
      # See: PDF2.0 s12.6.4.13, HexaPDF::Type::OptionalContentGroup
      class SetOCGState < Action

        define_field :S, type: Symbol, required: true, default: :SetOCGState
        define_field :State, type: PDFArray, required: true, default: []
        define_field :PreserveRB, type: Boolean, default: true

        STATE_TYPE_MAPPING = {on: :ON, ON: :ON, off: :OFF, OFF: :OFF, # :nodoc:
                              toggle: :Toggle, Toggle: :Toggle}

        # Adds a state changing sequence to the /State array.
        #
        # The +type+ argument specifies how the state of the given optional content groups should be
        # changed.
        #
        # +type+:: The type of sequence to add, either :on/:ON (for turning the OCGs on) , :off/:OFF
        #          (for turning the OCGs off), or :toggle/:Toggle (for toggling the state of the
        #          OCGs).
        #
        # +ocgs+:: A single optional content group or an array of optional content groups to which
        #          the state change defined with +type+ should be applied. The OCGs can be specified
        #          via their dictionary or by name which uses the first found OCG with that name.
        def add_state_change(type, ocgs)
          type = STATE_TYPE_MAPPING.fetch(type) do
            raise ArgumentError, "Invalid type #{type} specified, should be one of :on, :off or :toggle"
          end
          state = self[:State]
          state << type
          Array(ocgs).each do |ocg|
            if (ocg_name = ocg).kind_of?(String)
              ocg = document.optional_content.ocg(ocg_name, create: false)
              raise HexaPDF::Error, "Invalid OCG named '#{ocg_name}' specified" unless ocg
            end
            state << ocg
          end
        end

      end

    end
  end
end
