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

require 'strscan'
require 'hexapdf/error'
require 'hexapdf/reference'

module HexaPDF

  # Tokenizes the content of an IO object following the PDF rules.
  #
  # See: PDF2.0 s7.2
  class Tokenizer

    # Represents a keyword in a PDF file.
    class Token < String; end

    TOKEN_DICT_START = Token.new('<<'.b) # :nodoc:
    TOKEN_DICT_END = Token.new('>>'.b) # :nodoc:
    TOKEN_ARRAY_START = Token.new('['.b) # :nodoc:
    TOKEN_ARRAY_END = Token.new(']'.b) # :nodoc:

    # This object is returned when there are no more tokens to read.
    NO_MORE_TOKENS = ::Object.new
    def NO_MORE_TOKENS.to_s
      "EOS - no more tokens"
    end

    # Characters defined as whitespace.
    #
    # See: PDF2.0 s7.2.2
    WHITESPACE = " \n\r\0\t\f"

    # Characters defined as delimiters.
    #
    # See: PDF2.0 s7.2.2
    DELIMITER = "()<>{}/[]%"

    WHITESPACE_MULTI_RE = /[#{WHITESPACE}]+/ # :nodoc:

    WHITESPACE_OR_DELIMITER_RE = /(?=[#{Regexp.escape(WHITESPACE + DELIMITER)}])/ # :nodoc:

    # The IO object from the tokens are read.
    attr_reader :io

    # Creates a new tokenizer for the given IO stream.
    #
    # If +on_correctable_error+ is set to an object responding to +call(msg, pos)+, errors for
    # correctable situations are only raised if the return value of calling the object is +true+.
    def initialize(io, on_correctable_error: nil)
      @io = io
      @io_chunk = String.new(''.b)
      @ss = StringScanner.new(''.b)
      @original_pos = -1
      @on_correctable_error = on_correctable_error || proc { false }
      self.pos = 0
    end

    # Returns the current position of the tokenizer inside in the IO object.
    #
    # Note that this position might be different from +io.pos+ since the latter could have been
    # changed somewhere else.
    def pos
      @original_pos + @ss.pos
    end

    # Sets the position at which the next token should be read.
    #
    # Note that this does **not** set +io.pos+ directly (at the moment of invocation)!
    def pos=(pos)
      if pos >= @original_pos && pos <= @original_pos + @ss.string.size
        @ss.pos = pos - @original_pos
      else
        @original_pos = pos
        @next_read_pos = pos
        @ss.string.clear
        @ss.reset
      end
    end

    # Returns a single token read from the current position and advances the scan pointer.
    #
    # Comments and a run of whitespace characters are ignored. The value +NO_MORE_TOKENS+ is
    # returned if there are no more tokens available.
    def next_token
      prepare_string_scanner(20)
      prepare_string_scanner(20) while @ss.skip(WHITESPACE_MULTI_RE)
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
      when 123, 125 # { }
        Token.new(byte.chr.b)
      when 37 # %
        until @ss.skip_until(/(?=[\r\n])/)
          return NO_MORE_TOKENS unless prepare_string_scanner
        end
        next_token
      when -1 # we reached the end of the file
        NO_MORE_TOKENS
      else # everything else consisting of regular characters
        @ss.pos -= 1
        parse_keyword
      end
    end

    # Returns the next token but does not advance the scan pointer.
    def peek_token
      pos = self.pos
      tok = next_token
      self.pos = pos
      tok
    end

    # Returns the PDF object at the current position. This is different from #next_token because
    # references, arrays and dictionaries consist of multiple tokens.
    #
    # If the +allow_end_array_token+ argument is +true+, the ']' token is permitted to facilitate
    # the use of this method during array parsing.
    #
    # See: PDF2.0 s7.3
    def next_object(allow_end_array_token: false, allow_keyword: false)
      token = next_token

      if token.kind_of?(Token)
        case token
        when TOKEN_DICT_START
          token = parse_dictionary
        when TOKEN_ARRAY_START
          token = parse_array
        when TOKEN_ARRAY_END
          unless allow_end_array_token
            raise HexaPDF::MalformedPDFError.new("Found invalid end array token ']'", pos: pos)
          end
        else
          unless allow_keyword
            maybe_raise("Invalid object, got token #{token}", force: token !~ /^-?(nan|inf)$/i)
            token = 0
          end
        end
      end

      token
    end

    # Returns a single integer or keyword token read from the current position and advances the scan
    # pointer. If the current position doesn't contain such a token, +nil+ is returned without
    # advancing the scan pointer. The value +NO_MORE_TOKENS+ is returned if there are no more tokens
    # available.
    #
    # Initial runs of whitespace characters are ignored.
    #
    # Note: This is a special method meant for use with reconstructing the cross-reference table!
    def next_integer_or_keyword
      skip_whitespace
      byte = @ss.peek_byte || -1
      case byte
      when 48, 49, 50, 51, 52, 53, 54, 55, 56, 57
        parse_number
      when 97..122, 65..90
        parse_keyword
      when -1 # we reached the end of the file
        NO_MORE_TOKENS
      else
        nil
      end
    end

    # Reads the byte (an integer) at the current position and advances the scan pointer.
    def next_byte
      prepare_string_scanner(1)
      @ss.scan_byte
    end

    # Reads the cross-reference subsection entry at the current position and advances the scan
    # pointer.
    #
    # If a problem is detected, yields to caller where the argument +recoverable+ is truthy if the
    # problem is recoverable.
    #
    # See: PDF2.0 7.5.4
    def next_xref_entry #:yield: recoverable
      prepare_string_scanner(20)
      if !@ss.skip(/(\d{10}) (\d{5}) ([nf])(?: \r| \n|\r\n|(\r\r|\r|\n))/) || @ss[4]
        yield(@ss[4])
      end
      [@ss[1].to_i, @ss[2].to_i, @ss[3]]
    end

    # Skips all whitespace at the current position.
    #
    # See: PDF2.0 s7.2.2
    def skip_whitespace
      prepare_string_scanner
      prepare_string_scanner while @ss.skip(WHITESPACE_MULTI_RE)
    end

    # Utility method for scanning until the given regular expression matches.
    #
    # If the end of the file is reached in the process, +nil+ is returned. Otherwise the matched
    # string is returned.
    def scan_until(re)
      until (data = @ss.scan_until(re))
        return nil unless prepare_string_scanner
      end
      data
    end

    private

    TOKEN_CACHE = Hash.new {|h, k| h[k] = Token.new(k) } # :nodoc:
    TOKEN_CACHE['true'] = true
    TOKEN_CACHE['false'] = false
    TOKEN_CACHE['null'] = nil

    # Parses the keyword at the current position.
    #
    # See: PDF2.0 s7.2
    def parse_keyword
      str = scan_until(WHITESPACE_OR_DELIMITER_RE) || @ss.scan(/.*/)
      TOKEN_CACHE[str]
    end

    REFERENCE_RE = /[#{WHITESPACE}]+([+]?\d+)[#{WHITESPACE}]+R#{WHITESPACE_OR_DELIMITER_RE}/ # :nodoc:

    WHITESPACE_OR_DELIMITER_LUT = [] # :nodoc:
    (WHITESPACE + DELIMITER).each_byte {|x| WHITESPACE_OR_DELIMITER_LUT[x] = true }

    # Parses the number (integer or real) at the current position.
    #
    # See: PDF2.0 s7.3.3
    def parse_number
      prepare_string_scanner(40)
      pos = self.pos
      if (tmp = @ss.scan_integer)
        if @ss.eos? || WHITESPACE_OR_DELIMITER_LUT[@ss.peek_byte]
          # Handle object references, see PDF2.0 s7.3.10
          prepare_string_scanner(10)
          if @ss.scan(REFERENCE_RE)
            tmp = if tmp > 0
                    Reference.new(tmp, @ss[1].to_i)
                  else
                    maybe_raise("Invalid indirect object reference (#{tmp},#{@ss[1].to_i})")
                    nil
                  end
          end
          return tmp
        else
          self.pos = pos
        end
      end

      val = scan_until(WHITESPACE_OR_DELIMITER_RE) || @ss.scan(/.*/)
      if val.match?(/\A[+-]?(?:\d+\.\d*|\.\d+)\z/)
        val << '0' if val.getbyte(-1) == 46 # dot '.'
        Float(val)
      else
        TOKEN_CACHE[val] # val is keyword
      end
    end

    LITERAL_STRING_ESCAPE_MAP = { #:nodoc:
      'n' => "\n",
      'r' => "\r",
      't' => "\t",
      'b' => "\b",
      'f' => "\f",
      '(' => "(",
      ')' => ")",
      '\\' => "\\",
    }.freeze

    # Parses the literal string at the current position.
    #
    # See: PDF2.0 s7.3.4.2
    def parse_literal_string
      str = "".b
      parentheses = 1

      while parentheses != 0
        data = scan_until(/[()\\\r]/)
        unless data
          raise HexaPDF::MalformedPDFError.new("Unclosed literal string found", pos: pos)
        end

        str << data
        prepare_string_scanner if @ss.eos?
        case @ss.string.getbyte(@ss.pos - 1)
        when 41 then parentheses -= 1 # )
        when 40 then parentheses += 1 # (
        when 13 # \r
          str[-1] = "\n"
          @ss.pos += 1 if @ss.peek_byte == 10 # \n
        when 92 # \\
          str.chop!
          prepare_string_scanner(3)
          byte = @ss.get_byte
          if (data = LITERAL_STRING_ESCAPE_MAP[byte])
            str << data
          elsif byte == "\r" || byte == "\n"
            @ss.pos += 1 if byte == "\r" && @ss.peek(1) == "\n"
          elsif byte >= '0' && byte <= '7'
            byte += @ss.scan(/[0-7]{0,2}/)
            str << byte.oct.chr
          else
            str << byte
          end
        end
      end

      str.chop! # remove last parsed closing parenthesis
      str
    end

    # Parses the hex string at the current position.
    #
    # See: PDF2.0 s7.3.4.3
    def parse_hex_string
      data = scan_until(/(?=>)/)
      unless data
        raise HexaPDF::MalformedPDFError.new("Unclosed hex string found", pos: pos)
      end

      @ss.pos += 1
      data.tr!(WHITESPACE, "")
      [data].pack('H*')
    end

    # Parses the name at the current position.
    #
    # See: PDF2.0 s7.3.5
    def parse_name
      str = scan_until(WHITESPACE_OR_DELIMITER_RE) || @ss.scan(/.*/)
      str.gsub!(/#[A-Fa-f0-9]{2}/) {|m| m[1, 2].hex.chr }
      if str.force_encoding(Encoding::UTF_8).valid_encoding?
        str.to_sym
      else
        str.force_encoding(Encoding::BINARY).to_sym
      end
    end

    # Parses the array at the current position.
    #
    # It is assumed that the initial '[' has already been scanned.
    #
    # See: PDF2.0 s7.3.6
    def parse_array
      result = []
      while true
        obj = next_object(allow_end_array_token: true)
        if obj.equal?(TOKEN_ARRAY_END)
          break
        elsif obj.equal?(NO_MORE_TOKENS)
          raise HexaPDF::MalformedPDFError.new("Unclosed array found", pos: pos)
        end
        result << obj
      end
      result
    end

    # Parses the dictionary at the current position.
    #
    # It is assumed that the initial '<<' has already been scanned.
    #
    # See: PDF2.0 s7.3.7
    def parse_dictionary
      result = {}
      while true
        # Use #next_token because we either need a Name or the '>>' token here, the latter would
        # throw an error with #next_object.
        key = next_token
        break if key.equal?(TOKEN_DICT_END)
        unless key.kind_of?(Symbol)
          raise HexaPDF::MalformedPDFError.new("Dictionary keys must be PDF name objects, " \
                                               "found '#{key}'", pos: pos)
        end

        val = next_object
        next if val.nil?

        result[key] = val
      end
      result
    end

    # Prepares the StringScanner by filling its string instance with enough bytes.
    #
    # The number of needed bytes can be specified via the optional +needed_bytes+ argument.
    #
    # Returns +true+ if the end of the underlying IO stream has not been reached, yet.
    def prepare_string_scanner(needed_bytes = nil)
      return if needed_bytes && @ss.rest_size >= needed_bytes
      @io.seek(@next_read_pos)
      return false if @io.eof?

      @ss << @io.read(8192, @io_chunk)
      if @ss.pos > 8192 && @ss.string.length > 16384
        @ss.string.replace(@ss.string.byteslice(8192..-1))
        @ss.pos -= 8192
        @original_pos += 8192
      end
      @next_read_pos = @io.pos
      true
    end

    # Calls the @on_correctable_error callable object with the given message and the current
    # position. If the returned value is +true+, raises a HexaPDF::MalformedPDFError. Otherwise the
    # error is corrected (by the caller) and tokenization continues.
    #
    # If the option +force+ is used, the callable object is not called and the error is raised
    # immediately.
    def maybe_raise(msg, force: false)
      if force || @on_correctable_error.call(msg, pos)
        error = HexaPDF::MalformedPDFError.new(msg, pos: pos)
        error.set_backtrace(caller(1))
        raise error
      end
    end

  end

end
