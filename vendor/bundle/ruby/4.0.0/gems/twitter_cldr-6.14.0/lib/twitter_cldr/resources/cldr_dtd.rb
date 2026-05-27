# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Resources

    class CldrDTD
      class Attr
        attr_reader :name, :element_name, :dtd

        def initialize(name, element_name, dtd)
          @name = name
          @element_name = element_name
          @dtd = dtd
        end

        def values
          @values ||= begin
            attr_line_idx = schema.find_index do |line|
              line.include?("<!ATTLIST #{element_name} #{name} ")
            end

            return [] unless attr_line_idx

            attr_line = schema[attr_line_idx]

            if comment = find_match_comment_after(attr_line_idx + 1)
              parse_match(comment)
            else
              start_idx = attr_line.index('(')
              return [] unless start_idx

              finish_idx = attr_line.rindex(')')
              attr_line[(start_idx + 1)...finish_idx].split('|').map(&:strip)
            end
          end
        end

        private

        def find_match_comment_after(idx)
          loop do
            return nil if idx > schema.size

            if schema[idx].strip.start_with?('<!--@MATCH')
              break
            elsif schema[idx].strip.start_with?('<!--')
              idx += 1
            else
              return nil
            end
          end

          schema[idx]
        end

        def parse_match(str)
          m = str.match(/<!--@MATCH:([^\/]+)\/(.*)-->/)
          return [] unless m

          type, args = m.captures

          case type
            when 'literal'
              args.split(',').map(&:strip)
            when 'range'
              start, finish = args.split('~')
              ((start.to_i)..(finish.to_i)).to_a
          end
        end

        def schema
          dtd.schema
        end
      end

      attr_reader :cldr_requirement

      def initialize(cldr_requirement)
        @cldr_requirement = cldr_requirement
      end

      def find_attr(element_name, attr_name)
        elements[element_name] ||= {}
        elements[element_name][attr_name] ||= Attr.new(
          attr_name, element_name, self
        )
      end

      def schema
        @schema ||= File.read(schema_path).split("\n")
      end

      private

      def elements
        @elements ||= {}
      end

      def schema_path
        @schema_path ||= File.join(
          cldr_requirement.common_path, 'dtd', 'ldml.dtd'
        )
      end
    end

  end
end
