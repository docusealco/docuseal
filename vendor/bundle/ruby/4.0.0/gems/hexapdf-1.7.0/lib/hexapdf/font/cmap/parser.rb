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
require 'hexapdf/font/cmap'
require 'hexapdf/content/parser'

module HexaPDF
  module Font
    class CMap

      # Parses CMap files.
      #
      # See: Adobe Technical Notes #5014 and #5411
      class Parser

        # Parses the given string and returns a CMap object.
        def parse(string)
          tokenizer = HexaPDF::Content::Tokenizer.new(string)
          cmap = CMap.new

          until (token = tokenizer.next_token) == HexaPDF::Tokenizer::NO_MORE_TOKENS
            if token.kind_of?(HexaPDF::Tokenizer::Token)
              case token
              when 'beginbfchar' then parse_bf_char(tokenizer, cmap)
              when 'beginbfrange' then parse_bf_range(tokenizer, cmap)
              when 'begincidchar' then parse_cid_char(tokenizer, cmap)
              when 'begincidrange' then parse_cid_range(tokenizer, cmap)
              when 'begincodespacerange' then parse_codespace_range(tokenizer, cmap)
              when 'endcmap' then break
              end
            elsif token.kind_of?(Symbol)
              value = tokenizer.next_token
              if value.kind_of?(HexaPDF::Tokenizer::Token)
                parse_cmap(cmap, token) if value == 'usecmap'
              else
                parse_dict_mapping(cmap, token, value)
              end
            end
          end

          cmap
        rescue StandardError => e
          raise HexaPDF::Error, "Error parsing CMap: #{e.message}", e.backtrace
        end

        private

        # Populates the CMap with the values from the CMap with the given name.
        def parse_cmap(cmap, name)
          cmap.use_cmap(CMap.for_name(name.to_s))
        end

        # Parses a single mapping of a dictionary pair. The +name+ and +value+ of the mapping have
        # already been parsed.
        def parse_dict_mapping(cmap, name, value)
          case name
          when :Registry
            cmap.registry = value.force_encoding(::Encoding::UTF_8) if value.kind_of?(String)
          when :Ordering
            cmap.ordering = value.force_encoding(::Encoding::UTF_8) if value.kind_of?(String)
          when :Supplement
            cmap.supplement = value if value.kind_of?(Integer)
          when :CMapName
            cmap.name = value.to_s.dup.force_encoding(::Encoding::UTF_8) if value.kind_of?(Symbol)
          when :WMode
            cmap.wmode = value
          end
        end

        # Parses the "begincodespacerange" operator at the current position.
        def parse_codespace_range(tokenizer, cmap)
          until (code1 = tokenizer.next_token).kind_of?(HexaPDF::Tokenizer::Token)
            code2 = tokenizer.next_token
            byte_ranges = []
            code1.each_byte.with_index do |byte, index|
              byte_ranges << (byte..(code2.getbyte(index)))
            end
            cmap.add_codespace_range(*byte_ranges)
          end
        end

        # Parses the "cidchar" operator at the current position.
        def parse_cid_char(tokenizer, cmap)
          until (code = tokenizer.next_token).kind_of?(HexaPDF::Tokenizer::Token)
            cmap.add_cid_mapping(bytes_to_int(code), tokenizer.next_token)
          end
        end

        # Parses the "cidrange" operator at the current position.
        def parse_cid_range(tokenizer, cmap)
          until (code1 = tokenizer.next_token).kind_of?(HexaPDF::Tokenizer::Token)
            code1 = bytes_to_int(code1)
            code2 = bytes_to_int(tokenizer.next_token)
            cid_start = tokenizer.next_object

            if code1 == code2
              cmap.add_cid_mapping(code1, cid_start)
            else
              cmap.add_cid_range(code1, code2, cid_start)
            end
          end
        end

        # Parses the "bfchar" operator at the current position.
        def parse_bf_char(tokenizer, cmap)
          until (code = tokenizer.next_token).kind_of?(HexaPDF::Tokenizer::Token)
            str = tokenizer.next_token.encode!(::Encoding::UTF_8, ::Encoding::UTF_16BE)
            cmap.add_unicode_mapping(bytes_to_int(code), str)
          end
        end

        # Parses the "bfrange" operator at the current position.
        #
        #--
        # PDF2.0 s9.10.3 and Adobe Technical Note #5411 have different views as to how "bfrange"
        # operators of the form "startCode endCode codePoint" should be handled.
        #
        # PDF2.0 mentions that the last byte of "codePoint" should be incremented, up to a maximum
        # of 255. However #5411 has the range "<1379> <137B> <90FE>" as example which contradicts
        # this.
        #
        # Additionally, #5411 mentions in section 1.4.1 that the first byte of "startCode" and
        # "endCode" have to be the same. So it seems that this is a mistake in the PDF reference.
        #++
        def parse_bf_range(tokenizer, cmap)
          until (code1 = tokenizer.next_token).kind_of?(HexaPDF::Tokenizer::Token)
            code1 = bytes_to_int(code1)
            code2 = bytes_to_int(tokenizer.next_token)
            dest = tokenizer.next_object

            if dest.kind_of?(String)
              cmap.add_unicode_range_mapping(code1, code2, dest.unpack("n*"))
            elsif dest.kind_of?(Array)
              code1.upto(code2) do |code|
                str = dest[code - code1].encode!(::Encoding::UTF_8, ::Encoding::UTF_16BE)
                cmap.add_unicode_mapping(code, str)
              end
            else
              raise HexaPDF::Error, "Invalid bfrange operator in CMap"
            end
          end
        end

        # Treats the string as an array of bytes and converts it to an integer.
        #
        # The bytes are converted in the big-endian way.
        def bytes_to_int(string)
          result = 0
          index = 0
          while index < string.length
            result = (result << 8) | string.getbyte(index)
            index += 1
          end
          result
        end

      end

    end
  end
end
