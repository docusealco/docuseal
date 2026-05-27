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

require 'stringio'
require 'hexapdf/tokenizer'
require 'hexapdf/content/processor'

module HexaPDF
  module Content

    # More efficient tokenizer for content streams. This tokenizer class works directly on a
    # string and not on an IO.
    #
    # Changes:
    #
    # * Since a content stream is usually parsed front to back, a StopIteration error can be raised
    #   instead of returning +NO_MORE_TOKENS+ once the end of the string is reached to avoid costly
    #   checks in each iteration. If this behaviour is wanted, pass "raise_on_eos: true" in the
    #   constructor.
    #
    # * Indirect object references are *not* supported by this tokenizer!
    #
    # See: PDF2.0 s7.2
    class Tokenizer < HexaPDF::Tokenizer #:nodoc:

      # The string that is tokenized.
      attr_reader :string

      # Creates a new tokenizer.
      def initialize(string, raise_on_eos: false)
        @ss = StringScanner.new(string)
        @string = string
        @raise_on_eos = raise_on_eos
      end

      # See: HexaPDF::Tokenizer#pos
      def pos
        @ss.pos
      end

      # See: HexaPDF::Tokenizer#pos=
      def pos=(pos)
        @ss.pos = pos
      end

      # See: HexaPDF::Tokenizer#scan_until
      def scan_until(re)
        @ss.scan_until(re)
      end

      # See: HexaPDF::Tokenizer#next_token
      def next_token
        @ss.skip(WHITESPACE_MULTI_RE)
        case (byte = @ss.scan_byte || -1)
        when 43, 45, 46, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57 # + - . 0..9
          @ss.pos -= 1
          parse_number
        when 47 # /
          parse_name
        when 40 # (
          parse_literal_string
        when 60 # <
          if @ss.peek_byte == 60
            @ss.pos += 1
            TOKEN_DICT_START
          else
            parse_hex_string
          end
        when 62 # >
          unless @ss.scan_byte == 62
            raise HexaPDF::MalformedPDFError.new("Delimiter '>' found at invalid position", pos: pos - 1)
          end
          TOKEN_DICT_END
        when 91 # [
          TOKEN_ARRAY_START
        when 93 # ]
          TOKEN_ARRAY_END
        when 41 # )
          raise HexaPDF::MalformedPDFError.new("Delimiter ')' found at invalid position", pos: pos - 1)
        when 123, 125 # { } )
          Token.new(byte.chr.b)
        when 37 # %
          unless @ss.skip_until(/(?=[\r\n])/)
            (@raise_on_eos ? (raise StopIteration) : (return NO_MORE_TOKENS))
          end
          next_token
        when -1
          @raise_on_eos ? raise(StopIteration) : NO_MORE_TOKENS
        else
          @ss.pos -= 1
          parse_keyword
        end
      end

      private

      # See: HexaPDF::Tokenizer#parse_number
      def parse_number
        if (val = @ss.scan(/[+-]?(?:\d+\.\d*|\.\d+)/))
          val << '0' if val.getbyte(-1) == 46 # dot '.'
          Float(val)
        elsif (val = @ss.scan_integer)
          val.to_i
        else
          parse_keyword
        end
      end

      # Stub implementation to prevent errors for not-overridden methods.
      def prepare_string_scanner(*)
      end

    end

    # This class knows how to correctly parse a content stream.
    #
    # == Overview
    #
    # A content stream is mostly just a stream of PDF objects. However, there is one exception:
    # inline images.
    #
    # Since inline images don't follow the normal PDF object parsing rules, they need to be
    # handled specially and this is the reason for this class. Therefore only the BI operator is
    # ever called for inline images because the ID and EI operators are handled by the parser.
    #
    # To parse some contents the #parse method needs to be called with the contents to be parsed
    # and a Processor object which is used for processing the parsed operators.
    class Parser

      # Creates a new Parser object and calls #parse.
      def self.parse(contents, processor = nil, &block)
        new.parse(contents, processor, &block)
      end

      # Parses the contents and calls the processor object or the given block for each parsed
      # operator.
      #
      # If a full-blown Processor is not needed (e.g. because the graphics state doesn't need to be
      # maintained), one can use the block form to handle the parsed objects and their parameters.
      #
      # Note: The parameters array is reused for each processed operator, so duplicate it if
      # necessary.
      def parse(contents, processor = nil, &block) #:yields: object, params
        raise ArgumentError, "Argument processor or block is needed" if processor.nil? && block.nil?
        if processor.nil?
          block.singleton_class.send(:alias_method, :process, :call)
          processor = block
        end

        tokenizer = Tokenizer.new(contents, raise_on_eos: true)
        params = []
        loop do
          obj = tokenizer.next_object(allow_keyword: true)
          if obj.kind_of?(Tokenizer::Token)
            if obj == 'BI'
              params = parse_inline_image(tokenizer)
            end
            processor.process(obj.to_sym, params)
            params.clear
          else
            params << obj
          end
        end
      end

      private

      MAX_TOKEN_CHECK = 5 #:nodoc:

      # Parses the inline image at the current position.
      def parse_inline_image(tokenizer)
        # BI has already been read, so read the image dictionary
        dict = {}
        while (key = tokenizer.next_object(allow_keyword: true) rescue Tokenizer::NO_MORE_TOKENS)
          if key == 'ID'
            break
          elsif key == Tokenizer::NO_MORE_TOKENS
            raise HexaPDF::Error, "EOS while trying to read dictionary key for inline image"
          elsif !key.kind_of?(Symbol)
            raise HexaPDF::Error, "Inline image dictionary keys must be PDF name objects"
          end
          value = tokenizer.next_object rescue Tokenizer::NO_MORE_TOKENS
          if value == Tokenizer::NO_MORE_TOKENS
            raise HexaPDF::Error, "EOS while trying to read dictionary value for inline image"
          end
          dict[key] = value
        end

        # one whitespace character after ID
        tokenizer.next_byte

        real_end_found = false
        image_data = ''.b

        # find the EI operator and handle EI appearing inside the image data
        until real_end_found
          data = tokenizer.scan_until(/(?=EI(?:[#{Tokenizer::WHITESPACE}]|\z))/o)
          if data.nil?
            raise HexaPDF::Error, "End inline image marker EI not found"
          end
          image_data << data
          tokenizer.pos += 2
          last_pos = tokenizer.pos

          # Check if we found EI inside of the image data
          count = 0
          while count < MAX_TOKEN_CHECK
            token = tokenizer.next_object(allow_keyword: true) rescue Tokenizer::NO_MORE_TOKENS
            if token == Tokenizer::NO_MORE_TOKENS
              count += MAX_TOKEN_CHECK
            elsif token.kind_of?(Tokenizer::Token) &&
                !Processor::OPERATOR_MESSAGE_NAME_MAP.key?(token.to_sym)
              break #  invalid token
            end
            count += 1
          end

          if count >= MAX_TOKEN_CHECK
            real_end_found = true
          else
            image_data << "EI"
          end
          tokenizer.pos = last_pos
        end

        [dict, image_data]
      end

    end

  end
end
