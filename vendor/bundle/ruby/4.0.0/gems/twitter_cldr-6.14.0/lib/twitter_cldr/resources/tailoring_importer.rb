# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'nokogiri'

module TwitterCldr
  module Resources
    class TailoringImporter < Importer

      requirement :icu, '49.1'
      requirement :cldr, '21'
      output_path 'collation/tailoring'
      locales TwitterCldr.supported_locales
      ruby_engine :jruby

      SUPPORTED_RULES   = %w[p s t i pc sc tc ic x comment]
      SIMPLE_RULES      = %w[p s t i]
      LEVEL_RULE_REGEXP = /^(p|s|t|i)(c?)$/

      IGNORED_TAGS = %w[reset text #comment comment]

      LAST_BYTE_MASK = 0xFF

      LOCALES_MAP = {
        'zh-Hant': :'zh_Hant',
        id: :root,
        it: :root,
        ms: :root,
        nl: :root,
        pt: :root
      }

      EMPTY_TAILORING_DATA = {
        collator_options: {},
        tailored_table: '',
        suppressed_contractions: ''
      }

      class ImportError < RuntimeError; end

      private

      def execute
        FileUtils.mkdir_p(params[:output_path])
        params[:locales].each { |locale| import_locale(locale) }
      end

      def import_locale(locale)
        print "Importing %8s\t--\t" % locale

        if tailoring_present?(locale)
          dump(locale, tailoring_data(locale))
          puts "Done."
        else
          dump(locale, EMPTY_TAILORING_DATA)
          puts "Missing (generated empty tailoring resource)."
        end
      rescue ImportError => e
        puts "Error: #{e.message}"
      end

      def dump(locale, data)
        File.open(resource_file_path(locale), 'w') { |file| YAML.dump(data, file) }
      end

      def tailoring_present?(locale)
        File.file?(locale_file_path(locale))
      end

      def translated_locale(locale)
        LOCALES_MAP.fetch(locale, locale)
      end

      def locale_file_path(locale)
        File.join(
          requirements[:cldr].common_path, 'collation', "#{translated_locale(locale)}.xml"
        )
      end

      def resource_file_path(locale)
        File.join(params[:output_path], "#{locale}.yml")
      end

      def tailoring_data(locale)
        doc = get_collation_xml(locale).at_xpath('//collations')

        collations = doc.at_xpath('//collations')

        collation_alias = collations.at_xpath('alias[@path="//ldml/collations"]')
        aliased_locale  = collation_alias && collation_alias.attr('source')

        return tailoring_data(aliased_locale) if aliased_locale

        collation_type  = get_default_collation_type(collations)
        collation_rules = get_collation_rules(collations, collation_type)

        unless collation_rules
          language_type = doc.at_xpath('//identity/language').attr('type')
          # try to fall back to language collation (e.g., from zh-Hant to zh) with the same collation type
          if language_type != locale.to_s
            collations      = get_collation_xml(language_type).at_xpath('//collations')
            collation_rules = get_collation_rules(collations, collation_type)
          end
        end

        {
            collator_options:        parse_collator_options(collation_rules),
            tailored_table:          parse_tailorings(collation_rules, locale),
            suppressed_contractions: parse_suppressed_contractions(collation_rules)
        }
      end

      def get_collation_xml(locale)
        File.open(locale_file_path(locale)) { |file| Nokogiri::XML(file) }
      end

      def get_collation_rules(collations, collation_type)
        collations.at_xpath(%Q(collation[@type="#{collation_type || 'standard'}"]))
      end

      def get_default_collation_type(collations)
        default_type_node = collations.at_xpath('default[@type]')
        default_type_node && default_type_node.attr('type')
      end

      def get_class(name)
        requirements[:icu].get_class(name)
      end

      def collator_class
        @collator_class ||= get_class('com.ibm.icu.text.Collator')
      end

      def unicode_set_class
        @unicode_set_class ||= get_class('com.ibm.icu.text.UnicodeSet')
      end

      def collation_element_iterator_class
        @collation_element_iterator_class ||= get_class('com.ibm.icu.text.CollationElementIterator')
      end

      def parse_tailorings(data, locale)
        rules = data && data.at_xpath('rules')

        return '' unless rules

        collator = collator_class.get_instance(Java::JavaUtil::Locale.new(locale.to_s))

        rules.children.map do |child|
          validate_tailoring_rule(child)

          if child.name =~ LEVEL_RULE_REGEXP
            if $2.empty?
              table_entry_for_rule(collator, child.text)
            else
              child.text.chars.map { |char| table_entry_for_rule(collator, char) }
            end
          elsif child.name == 'x'
            context = ''
            child.children.inject([]) do |memo, c|
              if SIMPLE_RULES.include?(c.name)
                memo << table_entry_for_rule(collator, context + c.text)
              elsif c.name == 'context'
                context = c.text
              elsif c.name == 'comment'
              elsif c.name != 'extend'
                raise ImportError, "Rule '#{c.name}' inside <x></x> is not supported."
              end

              memo
            end
          else
            raise ImportError, "Tag '#{child.name}' is not supported." unless IGNORED_TAGS.include?(child.name)
          end
        end.flatten.compact.join("\n")
      end

      def table_entry_for_rule(collator, tailored_value)
        code_points = get_code_points(tailored_value).map { |cp| cp.to_s(16).upcase.rjust(4, '0') }

        collation_elements = get_collation_elements(collator, tailored_value).map do |ce|
          ce.map { |l| l.to_s(16).upcase }.join(', ')
        end

        "#{code_points.join(' ')}; [#{collation_elements.join('][')}]"
      end

      def parse_suppressed_contractions(data)
        node = data && data.at_xpath('suppress_contractions')
        node ? unicode_set_class.to_array(unicode_set_class.new(node.text)).to_a.join : ''
      end

      def parse_collator_options(data)
        options = {}

        if data
          case_first_setting = data.at_xpath('settings[@caseFirst]')
          options['case_first'] = case_first_setting.attr('caseFirst').to_sym if case_first_setting
        end

        TwitterCldr::Utils.deep_symbolize_keys(options)
      end

      def validate_tailoring_rule(rule)
        return if IGNORED_TAGS.include?(rule.name)

        raise ImportError, "Rule '#{rule.name}' is not supported." unless SUPPORTED_RULES.include?(rule.name)
      end

      def get_collation_elements(collator, string)
        iter = collator.get_collation_element_iterator(string)

        collation_elements = []
        ce = iter.next

        while ce != collation_element_iterator_class::NULLORDER
          p1 = (ce >> 24) & LAST_BYTE_MASK
          p2 = (ce >> 16) & LAST_BYTE_MASK

          primary   = p2.zero? ? p1 : (p1 << 8) + p2
          secondary = (ce >> 8) & LAST_BYTE_MASK
          tertiarly = ce & LAST_BYTE_MASK

          collation_elements << [primary, secondary, tertiarly]

          ce = iter.next
        end

        collation_elements
      end

      def get_code_points(string)
        TwitterCldr::Utils::CodePoints.from_string(TwitterCldr::Normalization.normalize(string))
      end

    end

  end
end
