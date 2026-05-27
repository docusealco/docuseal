# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'forwardable'
require 'nokogiri'

module TwitterCldr
  module Resources
    class CldrDocumentSet

      class Element
        extend Forwardable

        def_delegators :@element, :attribute, :content, :name, :path

        attr_reader :docset, :element

        def initialize(docset, element)
          @docset = docset
          @element = element
        end

        def xpath(path)
          path = CldrDocumentSet.join_xpaths(docset.path_for(element), path)
          docset.xpath(path)
        end
      end

      class ElementList
        include Enumerable
        extend Forwardable

        def_delegators :@elements, :size

        attr_reader :docset, :elements

        def initialize(docset, elements)
          @docset = docset
          @elements = elements
        end

        def [](idx)
          return unless elements[idx]

          Element.new(docset, elements[idx])
        end

        def first
          self[0]
        end

        def each
          return to_enum(__method__) unless block_given?

          elements.size.times do |idx|
            yield self[idx]
          end
        end
      end


      def self.join_xpaths(*paths)
        segments = paths.flat_map { |a| a.chomp('/').split('/') }
        segments = segments.each_with_object([]) do |segment, result|
          if segment == '..'
            result.pop
          else
            result << segment
          end
        end
        segments.join('/')
      end

      attr_reader :path, :cldr_locale, :cldr_requirement

      def initialize(path, cldr_locale, cldr_requirement)
        @path = path
        @cldr_locale = cldr_locale
        @cldr_requirement = cldr_requirement
      end


      def xpath(path)
        cldr_locale.ancestors.each do |ancestor_locale|
          data = doc_for(ancestor_locale).xpath(path)

          unless data.empty?
            return ElementList.new(self, resolve_aliases_in(data))
          end
        end

        ElementList.new(self, [])
      end

      def path_for(node)
        orig_node = node
        path = []

        while node
          path << selector_for(node)
          node = node.parent
          break if node.name == 'document'
        end

        "//#{path.reverse.join('/')}"
      end

      private

      def resolve_aliases_in(data)
        alias_nodes = data.xpath('.//alias')
        alias_nodes.each do |alias_node|
          alias_path = alias_node.attribute('path').value
          full_path = join_xpaths(path_for(alias_node.parent), alias_path)

          cldr_locale.ancestors.find do |ancestor_locale|
            resolved_node = doc_for(ancestor_locale).xpath(full_path).first.dup

            if resolved_node
              resolved_copy = Nokogiri::XML(resolved_node.to_xml).children.first
              parent = alias_node.parent
              alias_node.replace(resolved_copy.children)
              resolve_aliases_in(parent)
              break
            end
          end
        end

        data
      end

      def join_xpaths(*paths)
        self.class.join_xpaths(*paths)
      end

      def selector_for(node)
        node.name.dup.tap do |selector|
          if type = node.attribute('type')
            selector << "[@type='#{type.value}']"
          end
        end
      end

      def doc_for(locale)
        locale_fs = locale.to_s.gsub('-', '_')
        docs[locale_fs] ||= Nokogiri.XML(File.read(File.join(path, "#{locale_fs}.xml")))
      end

      def docs
        @docs ||= {}
      end
    end

  end
end
