# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'base64'
require 'fileutils'
require 'nokogiri'
require 'yaml'

module TwitterCldr
  module Resources

    class SegmentRulesImporter < Importer

      # @TODO: moar boundary types
      BOUNDARY_TYPES = {
        'word'      => 'word',
        'sentence'  => 'sentence',
        'grapheme'  => 'grapheme',
        'line'      => 'line'  # loose, normal, strict
      }.freeze

      TYPES_TO_ATTRS = {
        'word'     => 'WordBreak',
        'sentence' => 'SentenceBreak',
        'grapheme' => 'GraphemeClusterBreak',
        'line'     => 'LineBreak'
      }.freeze

      Locale = TwitterCldr::Shared::Locale

      StateTable    = TwitterCldr::Segmentation::StateTable
      StatusTable   = TwitterCldr::Segmentation::StatusTable
      CategoryTable = TwitterCldr::Segmentation::CategoryTable

      requirement :icu, Versions.icu_version
      requirement :cldr, Versions.cldr_version
      output_path File.join('shared', 'segments')
      ruby_engine :jruby

      def execute
        each_locale do |locale, doc|
          BOUNDARY_TYPES.each do |kind, icu_kind|
            seg = doc.xpath(
              "//ldml/segmentations/segmentation[@type=\"#{TYPES_TO_ATTRS[kind]}\"]"
            )

            rule_data = rule_data_for(icu_kind, locale, seg)

            unless rule_data.empty?
              output_dir = File.join(output_path, 'rules', locale)
              output_file = File.join(output_dir, "#{kind}.yml")
              FileUtils.mkdir_p(output_dir)
              File.write(output_file, YAML.dump(rule_data))
            end

            suppressions = suppressions_for(icu_kind, locale, seg)

            unless suppressions.empty?
              output_dir = File.join(output_path, 'suppressions', locale)
              output_file = File.join(output_dir, "#{kind}.yml")
              FileUtils.mkdir_p(output_dir)
              File.write(output_file, YAML.dump(suppressions))
            end
          end
        end
      end

      private

      def each_locale
        return to_enum(__method__) unless block_given?

        pattern = File.join(requirements[:cldr].common_path, 'segments', '*.xml')

        Dir.glob(pattern).each do |file, ret|
          locale = File.basename(file).chomp('.xml').tr('_', '-')
          yield locale, Nokogiri::XML(File.read(file))
        end
      end

      def rule_data_for(kind, locale, doc)
        vars = doc.xpath('variables/variable')
        rules = doc.xpath('segmentRules/rule')
        result = {}

        unless vars.empty? && rules.empty?
          result.merge!(encode_rbbi_data(rbbi_data_for(kind, locale)))
        end

        result
      end

      def suppressions_for(kind, locale, doc)
        suppressions = doc.xpath('suppressions/suppression').map(&:text)
        return {} if suppressions.empty?

        encode_suppressions(suppressions)
      end

      def encode_rbbi_data(data)
        {
          metadata: metadata_from(data),
          forward_table: StateTable.new(data.fFTable.fTable.to_a, data.fFTable.fFlags).dump16,
          backward_table: StateTable.new(data.fRTable.fTable.to_a, data.fRTable.fFlags).dump16,
          status_table: StatusTable.new(data.fStatusTable.to_a).dump,
          category_table: encode_trie(data.fTrie),  # this really isn't a trie
        }
      end

      def metadata_from(data)
        {
          category_count: data.fHeader.fCatCount,
          lookahead_results_size: data.fFTable.fLookAheadResultsSize
        }
      end

      def encode_suppressions(suppressions)
        forwards_trie = TwitterCldr::Utils::Trie.new
        backwards_trie = TwitterCldr::Utils::Trie.new

        suppressions.each do |suppression|
          forwards_trie.add(suppression.codepoints, true)
          backwards_trie.add(suppression.reverse.codepoints, true)
        end

        {
          forwards_trie: Marshal.dump(forwards_trie),
          backwards_trie: Marshal.dump(backwards_trie)
        }
      end

      def encode_trie(trie)
        arr = [].tap do |results|
          iter = trie.iterator

          while iter.hasNext
            range = iter.next
            results << range_to_a(range)

            # this should be the last entry, but for some reason ICU returns
            # one more out-of-order range past the Unicode max
            break if range.getEnd == 0x10FFFF
          end
        end

        # @TODO: Distinguish between the 16- and 32-bit flavors
        CategoryTable.new(arr).dump16.strip
      end

      def range_to_a(range)
        [range.getStart, range.getEnd, range.getValue]
      end

      def rbbi_data_for(kind, locale)
        bundle = bundle_for(ulocale_class.new(locale))
        brkf_name = bundle.getStringWithFallback("boundaries/#{kind}")
        buffer = icu_binary.getData("#{brkiter_name}/#{brkf_name}")
        rbbi_data_wrapper.get(buffer)
      end

      def bundle_for(locale)
        @bundle ||= resource_bundle.getBundleInstance(brkiter_base_name, locale, locale_root)
      end

      def brkiter_name
        @brkiter_name ||= icu_data.const_get(:ICU_BRKITR_NAME)
      end

      def brkiter_base_name
        @brkiter_base_name ||= icu_data.const_get(:ICU_BRKITR_BASE_NAME)
      end

      def locale_root
        @locale_root ||= resource_bundle.const_get(:OpenType).const_get(:LOCALE_ROOT)
      end

      def rbbi_data_wrapper
        @rbbi_data_wrapper ||= requirements[:icu].get_class('com.ibm.icu.impl.RBBIDataWrapper')
      end

      def icu_binary
        @icu_binary ||= requirements[:icu].get_class('com.ibm.icu.impl.ICUBinary')
      end

      def icu_data
        @icu_data ||= requirements[:icu].get_class('com.ibm.icu.impl.ICUData')
      end

      def resource_bundle
        @bundle_class ||= requirements[:icu].get_class('com.ibm.icu.impl.ICUResourceBundle')
      end

      def ulocale_class
        @ulocale_class ||= requirements[:icu].get_class('com.ibm.icu.util.ULocale')
      end

      def output_path
        params[:output_path]
      end

    end
  end
end
