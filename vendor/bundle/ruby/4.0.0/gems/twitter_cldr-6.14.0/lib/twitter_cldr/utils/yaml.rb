# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

# This code was adapted from the ya2yaml gem, maintained by Akira Funai.
# https://github.com/afunai/ya2yaml

# Copyright (c) 2006 Akira FUNAI <funai.akira@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.


module TwitterCldr
  module Utils

    class YAML

      UCS_0X85   = [0x85].pack('U')   #   c285@UTF8 Unicode next line
      UCS_0XA0   = [0xa0].pack('U')   #   c2a0@UTF8 Unicode non-breaking space
      UCS_0X2028 = [0x2028].pack('U') # e280a8@UTF8 Unicode line separator
      UCS_0X2029 = [0x2029].pack('U') # e280a9@UTF8 Unicode paragraph separator

      # non-break characters
      ESCAPE_SEQ = {
        "\x00" => '\\0',
        "\x07" => '\\a',
        "\x08" => '\\b',
        "\x0b" => '\\v',
        "\x0c" => '\\f',
        "\x1b" => '\\e',
        "\""   => '\\"',
        "\\"   => '\\\\',
      }

      # non-breaking space
      ESCAPE_SEQ_NS = {
        UCS_0XA0 => '\\_',
      }

      # white spaces
      ESCAPE_SEQ_WS = {
        "\x09" => '\\t',
        " "    => '\\x20',
      }

      # line breaks
      ESCAPE_SEQ_LB ={
        "\x0a"     => '\\n',
        "\x0d"     => '\\r',
        UCS_0X85   => '\\N',
        UCS_0X2028 => '\\L',
        UCS_0X2029 => '\\P',
      }

      # regexps for line breaks
      REX_LF   = Regexp.escape("\x0a")
      REX_CR   = Regexp.escape("\x0d")
      REX_CRLF = Regexp.escape("\x0d\x0a")
      REX_NEL  = Regexp.escape(UCS_0X85)
      REX_LS   = Regexp.escape(UCS_0X2028)
      REX_PS   = Regexp.escape(UCS_0X2029)

      REX_ANY_LB    = /(#{REX_LF}|#{REX_CR}|#{REX_NEL}|#{REX_LS}|#{REX_PS})/
      REX_NORMAL_LB = /(#{REX_LF}|#{REX_LS}|#{REX_PS})/

      # regexps for language-Independent types for YAML1.1
      REX_BOOL = /
         y|Y|yes|Yes|YES|n|N|no|No|NO
        |true|True|TRUE|false|False|FALSE
        |on|On|ON|off|Off|OFF
      /x
      REX_FLOAT = /
         [-+]?([0-9][0-9_]*)?\.[0-9.]*([eE][-+][0-9]+)? # (base 10)
        |[-+]?[0-9][0-9_]*(:[0-5]?[0-9])+\.[0-9_]*      # (base 60)
        |[-+]?\.(inf|Inf|INF)                           # (infinity)
        |\.(nan|NaN|NAN)                                # (not a number)
      /x
      REX_INT = /
         [-+]?0b[0-1_]+                   # (base 2)
        |[-+]?0[0-7_]+                    # (base 8)
        |[-+]?(0|[1-9][0-9_]*)            # (base 10)
        |[-+]?0x[0-9a-fA-F_]+             # (base 16)
        |[-+]?[1-9][0-9_]*(:[0-5]?[0-9])+ # (base 60)
      /x
      REX_MERGE = /
        <<
      /x
      REX_NULL = /
         ~              # (canonical)
        |null|Null|NULL # (English)
        |               # (Empty)
      /x
      REX_TIMESTAMP = /
         [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] # (ymd)
        |[0-9][0-9][0-9][0-9]                       # (year)
         -[0-9][0-9]?                               # (month)
         -[0-9][0-9]?                               # (day)
         ([Tt]|[ \t]+)[0-9][0-9]?                   # (hour)
         :[0-9][0-9]                                # (minute)
         :[0-9][0-9]                                # (second)
         (\.[0-9]*)?                                # (fraction)
         (([ \t]*)Z|[-+][0-9][0-9]?(:[0-9][0-9])?)? # (time zone)
      /x
      REX_VALUE = /
        =
      /x
      REX_SYMBOL = /
        \A:.*
      /x

      class << self

        def dump(obj, opts = {})
          @options = opts.dup
          @options[:indent_size] = 2          if @options[:indent_size].to_i <= 0
          @options[:minimum_block_length] = 0 if @options[:minimum_block_length].to_i <= 0
          @options.update(
            {
              printable_with_syck:  true,
              escape_b_specific:    true,
              escape_as_utf8:       true,
            }
          ) if @options[:syck_compatible]

          "--- #{emit(obj, 1)}\n"
        rescue SystemStackError
          raise ArgumentError, "TwitterCLDR yaml dumper can't handle circular references"
        end

        private

        def emit(obj, level)
          case obj
            when Array
              if (obj.length == 0)
                '[]'
              else
                indent = "\n#{s_indent(level - 1)}"
                obj.collect do |o|
                  "#{indent}- #{emit(o, level + 1)}"
                end.join('')
              end
            when Hash
              if (obj.length == 0)
                '{}'
              else
                indent = "\n#{s_indent(level - 1)}"
                hash_order = @options[:hash_order]
                if (hash_order && level == 1)
                  hash_keys = obj.keys.sort do |x, y|
                    x_order = hash_order.index(x) ? hash_order.index(x) : Float::MAX
                    y_order = hash_order.index(y) ? hash_order.index(y) : Float::MAX
                    o = (x_order <=> y_order)
                    (o != 0) ? o : (x.to_s <=> y.to_s)
                  end
                elsif @options[:preserve_order]
                  hash_keys = obj.keys
                else
                  hash_keys = obj.keys.sort { |x, y| x.to_s <=> y.to_s }
                end
                hash_keys.collect do |k|
                  key = emit(k, level + 1)
                  if (
                    is_one_plain_line?(key) ||
                    key =~ /\A(#{REX_BOOL}|#{REX_FLOAT}|#{REX_INT}|#{REX_NULL}|#{REX_SYMBOL})\z/x
                  )
                    "#{indent}#{key}: #{emit(obj[k], level + 1)}"
                  else
                    "#{indent}? #{key}#{indent}: #{emit(obj[k], level + 1)}"
                  end
                end.join('')
              end
            when NilClass
              '~'
            when String
              emit_string(obj, level)
            when TrueClass, FalseClass
              obj.to_s
            when Integer, Float
              obj.to_s
            when Date
              obj.to_s
            when Time
              offset = obj.gmtoff
              off_hm = sprintf(
                '%+.2d:%.2d',
                (offset / 3600.0).to_i,
                (offset % 3600.0) / 60
              )
              u_sec = (obj.usec != 0) ? sprintf(".%.6d", obj.usec) : ''
              obj.strftime("%Y-%m-%d %H:%M:%S#{u_sec} #{off_hm}")
            when Symbol
              prefix = @options[:use_natural_symbols] && is_one_plain_line?(obj.to_s) ? ":" : "!ruby/symbol "
              "#{prefix}#{emit_string(obj, level)}"
            when Range
              '!ruby/range ' + obj.to_s
            when Regexp
              '!ruby/regexp ' + obj.inspect
            else
              case
                when obj.is_a?(Struct)
                  struct_members = {}
                  obj.each_pair { |k, v| struct_members[k.to_s] = v }
                  "!ruby/struct:#{obj.class.to_s.sub(/^(Struct::(.+)|.*)$/, '\2')} #{emit(struct_members, level + 1)}"
                else
                  # serialized as a generic object
                  object_members = {}
                  obj.instance_variables.each do |k, v|
                    object_members[k.to_s.sub(/^@/, '')] = obj.instance_variable_get(k)
                  end
                  "!ruby/object:#{obj.class.to_s} #{emit(object_members, level + 1)}"
              end
          end
        end

        def emit_string(str, level)
          if @options[:quote_all_strings] && !str.is_a?(Symbol)
            emit_quoted_string(str, level)
          else
            str = str.to_s
            (is_string, is_printable, is_one_line, is_one_plain_line) = string_type(str)
            if is_string
              if is_printable
                if is_one_plain_line
                  emit_simple_string(str, level)
                else
                  (is_one_line || str.length < @options[:minimum_block_length]) ?
                    emit_quoted_string(str, level) :
                    emit_block_string(str, level)
                end
              else
                emit_quoted_string(str, level)
              end
            else
              emit_base64_binary(str, level)
            end
          end
        end

        def emit_simple_string(str, level)
          str
        end

        def emit_block_string(str, level)
          str = normalize_line_break(str)

          indent = s_indent(level)
          indentation_indicator = (str =~ /\A /) ? indent.size.to_s : ''
          str =~ /(#{REX_NORMAL_LB}*)\z/
          chomping_indicator = case $1.length
            when 0
              '-'
            when 1
              ''
            else
              '+'
          end

          str.chomp!
          str.gsub!(/#{REX_NORMAL_LB}/) { $1 + indent }
          "|#{indentation_indicator}#{chomping_indicator}\n#{indent}#{str}"
        end

        def emit_quoted_string(str, level)
          str = yaml_escape(normalize_line_break(str))
          if (str.length < @options[:minimum_block_length])
            str.gsub!(/#{REX_NORMAL_LB}/) { ESCAPE_SEQ_LB[$1] }
          else
            str.gsub!(/#{REX_NORMAL_LB}$/) { ESCAPE_SEQ_LB[$1] }
            str.gsub!(/(#{REX_NORMAL_LB}+)(.)/) do
              trail_c = $3
              $1 + trail_c.sub(/([\t ])/) { ESCAPE_SEQ_WS[$1] }
            end
            indent = s_indent(level)
            str.gsub!(/#{REX_NORMAL_LB}/) { "#{ESCAPE_SEQ_LB[$1]}\\\n#{indent}" }
          end
          %Q("#{str}")
        end

        def emit_base64_binary(str, level)
          indent = "\n#{s_indent(level)}"
          base64 = [str].pack('m')
          "!binary |#{indent}#{base64.gsub(/\n(?!\z)/, indent)}"
        end

        def string_type(str)
          if str.respond_to?(:encoding) && (!str.valid_encoding? || str.encoding == Encoding::ASCII_8BIT)
            return false, false, false, false
          end
          (ucs_codes = str.unpack('U*')) rescue (
            # ArgumentError -> binary data
            return false, false, false, false
          )
          if (
            @options[:printable_with_syck] &&
            str =~ /\A#{REX_ANY_LB}* | #{REX_ANY_LB}*\z|#{REX_ANY_LB}{2}\z/
          )
            # detour Syck bug
            return true, false, nil, false
          end
          ucs_codes.each {|ucs_code|
            return true, false, nil, false unless is_printable?(ucs_code)
          }
          return true, true, is_one_line?(str), is_one_plain_line?(str)
        end

        def is_printable?(ucs_code)
          # YAML 1.1 / 4.1.1.
          (
            [0x09, 0x0a, 0x0d, 0x85].include?(ucs_code)   ||
            (ucs_code <=     0x7e && ucs_code >=    0x20) ||
            (ucs_code <=   0xd7ff && ucs_code >=    0xa0) ||
            (ucs_code <=   0xfffd && ucs_code >=  0xe000) ||
            (ucs_code <= 0x10ffff && ucs_code >= 0x10000)
          ) &&
          !(
            # treat LS/PS as non-printable characters
            @options[:escape_b_specific] &&
            (ucs_code == 0x2028 || ucs_code == 0x2029)
          )
        end

        def is_one_line?(str)
          str !~ /#{REX_ANY_LB}(?!\z)/
        end

        def is_one_plain_line?(str)
          # YAML 1.1 / 4.6.11.
          str !~ /^([\-\?:,\[\]\{\}\#&\*!\|>'"%@`\s]|---|\.\.\.)/    &&
          str !~ /[:\#\s\[\]\{\},]/                                  &&
          str !~ /#{REX_ANY_LB}/                                     &&
          str !~ /^(#{REX_BOOL}|#{REX_FLOAT}|#{REX_INT}|#{REX_MERGE}
            |#{REX_NULL}|#{REX_TIMESTAMP}|#{REX_VALUE})$/x
        end

        def s_indent(level)
          # YAML 1.1 / 4.2.2.
          ' ' * (level * @options[:indent_size])
        end

        def normalize_line_break(str)
          # YAML 1.1 / 4.1.4.
          str.gsub(/(#{REX_CRLF}|#{REX_CR}|#{REX_NEL})/, "\n")
        end

        def yaml_escape(str)
          # YAML 1.1 / 4.1.6.
          str.gsub(/[^a-zA-Z0-9]/u) do |c|
            ucs_code, = (c.unpack('U') rescue [??])
            case
              when ESCAPE_SEQ[c]
                ESCAPE_SEQ[c]
              when is_printable?(ucs_code)
                c
              when @options[:escape_as_utf8]
                c.respond_to?(:bytes) ?
                  c.bytes.collect { |b| '\\x%.2x' % b }.join :
                  '\\x' + c.unpack('H2' * c.size).join('\\x')
              when ucs_code == 0x2028 || ucs_code == 0x2029
                ESCAPE_SEQ_LB[c]
              when ucs_code <= 0x7f
                sprintf('\\x%.2x', ucs_code)
              when ucs_code <= 0xffff
                sprintf('\\u%.4x', ucs_code)
              else
                sprintf('\\U%.8x', ucs_code)
            end
          end
        end

      end

    end

  end
end
