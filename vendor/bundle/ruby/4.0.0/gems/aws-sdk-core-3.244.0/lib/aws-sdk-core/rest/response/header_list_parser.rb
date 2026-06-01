# frozen_string_literal: true

require 'strscan'

module Aws
  module Rest
    module Response
      # @api private
      module HeaderListParser

        class << self
          # parse a list of possibly quoted and escaped string values
          # Follows:
          # # [RFC-7230's specification of header values](https://datatracker.ietf.org/doc/html/rfc7230#section-3.2.6).
          def parse_string_list(value)
            buffer = StringScanner.new(value)
            parsed = []

            parsed << read_value(buffer) until buffer.eos?

            parsed
          end

          def parse_timestamp_list(value, ref)
            # timestamp lists use an http-date by default and are unescaped
            # eg: Mon, 16 Dec 2019 23:48:18 GMT, Mon, 16 Dec 2019 23:48:18 GMT
            case ref['timestampFormat'] || ref.shape['timestampFormat']
            when 'unixTimestamp'
              value.split(', ').map { |v| Time.at(v.to_f) }
            when 'iso8601' then value.split(', ').map { |v| Time.parse(v) }
            else
              # header default to rfc822/http-date, which has a comma after day
              value.split(',').each_slice(2).map { |v| Time.parse(v[0] + v[1])}
            end
          end

          private

          def read_value(buffer)
            until buffer.eos?
              case buffer.peek(1)
              when ' ', "\t"
                # drop leading whitespace
                buffer.getch
                next
              when '"'
                buffer.getch # drop the quote and advance
                return read_quoted_value(buffer)
              else
                return read_unquoted_value(buffer)
              end
            end
            # buffer is only whitespace
            nil
          end

          def read_unquoted_value(buffer)
            # there cannot be any escaped values
            value = buffer.scan_until(/,|$/)
            # drop the comma if we matched it
            buffer.matched == ',' ? value.chop : value
          end

          def read_quoted_value(buffer)
            # scan until we have an unescaped double quote
            value = buffer.scan_until(/[^\\]"/)
            raise ArgumentError, 'Invalid String list: No closing quote found' unless value

            # drop any remaining whitespace/commas
            buffer.scan_until(/[\s,]*/)
            # the last character will always be the closing quote.
            # Add a starting quote  and then unescape (undump)
            "\"#{value}".undump
          end
        end
      end
    end
  end
end
