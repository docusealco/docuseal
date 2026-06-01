# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Shared
    class Locale

      class << self
        # http://unicode.org/reports/tr35/tr35-9.html#Likely_Subtags
        #
        # 1. Make sure the input locale is in canonical form: uses the right
        #    separator, and has the right casing.
        #
        # 2. Replace any deprecated subtags with their canonical values using
        #    the <alias> data in supplemental metadata. Use the first value in
        #    the replacement list, if it exists.
        #
        # 3. If the tag is grandfathered (see <variable id="$grandfathered"
        #    type="choice"> in the supplemental data), then return it.
        #    (NOTE: grandfathered subtags are no longer part of CLDR)
        #
        # 4. Remove the script code 'Zzzz' and the region code 'ZZ' if they
        #    occur; change an empty language subtag to 'und'.
        #
        # 5. Get the components of the cleaned-up tag (language¹, script¹, and
        #    region¹), plus any variants if they exist (including keywords).
        def parse(locale_text)
          locale_text = locale_text.to_s.strip

          normalize(locale_text).tap do |locale|
            replace_aliased_subtags(locale)
            remove_placeholder_tags(locale)
          end
        end

        def valid?(locale_text)
          # make sure all subtags have at least one identity, i.e. they exist
          # in one of the language/script/region/variant lists
          identify_subtags(locale_text.strip).all? do |subtag|
            !subtag.last.empty?
          end
        end

        def parse_likely(locale_text)
          LikelySubtags.locale_for(locale_text)
        end

        def split(locale_text)
          locale_text.strip.split(/[-_ ]/)
        end

        private

        def normalize(locale_text)
          Locale.new(nil).tap do |locale|
            subtags = identify_subtags(locale_text)

            until subtags.empty?
              subtag, identities = subtags.shift
              next if identities.empty?

              identities.each do |identity|
                unless subtag_set?(locale, identity)
                  set_subtag(locale, identity, subtag)
                  break
                end
              end
            end
          end
        end

        def subtag_set?(locale, identity)
          case identity
            when :variant
              false
            else
              !!locale.send(identity)
          end
        end

        def set_subtag(locale, identity, subtag)
          case identity
            when :variant
              locale.variants << normalize_subtag(subtag, identity)
            else
              locale.send(
                :"#{identity}=", normalize_subtag(subtag, identity)
              )
          end
        end

        def identify_subtags(locale_text)
          split(locale_text).map do |subtag|
            identities = identify_subtag(subtag)
            [subtag, identities]
          end
        end

        def identify_subtag(subtag)
          [].tap do |types|
            types << :language if language?(subtag)
            types << :script   if script?(subtag)
            types << :region   if region?(subtag)
            types << :variant  if variant?(subtag)

            types << :language if language?(normalize_subtag(subtag, :language))
            types << :script   if script?(normalize_subtag(subtag, :script))
            types << :region   if region?(normalize_subtag(subtag, :region))
            types << :variant  if variant?(normalize_subtag(subtag, :variant))
          end
        end

        def language?(subtag)
          languages.include?(subtag) || language_aliases.include?(subtag.to_sym)
        end

        def script?(subtag)
          scripts.include?(subtag) ||
            !!PropertyValueAliases.long_alias_for('sc', subtag)
        end

        def region?(subtag)
          territories.include?(subtag) || region_aliases.include?(subtag.to_sym)
        end

        def variant?(subtag)
          subtag = normalize_subtag(subtag, :variant)
          variants.include?(subtag)
        end

        def region_aliases
          @region_aliases ||= aliases_resource[:territory].each_with_object({}) do |(_, aliases), ret|
            ret.merge!(aliases)
          end
        end

        def language_aliases
          @language_aliases ||= aliases_resource[:language].each_with_object({}) do |(_, aliases), ret|
            ret.merge!(aliases)
          end
        end

        def normalize_subtag(subtag, identity)
          case identity
            when :language
              subtag.downcase
            when :script
              subtag.capitalize
            when :region, :variant
              subtag.upcase
          end
        end

        def replace_aliased_subtags(locale)
          replace_aliased_language_subtags(locale)
          replace_aliased_region_subtags(locale)
        end

        def replace_aliased_language_subtags(locale)
          language = locale.language ? locale.language.to_sym : nil
          if found_alias = language_aliases[language]
            locale.language = found_alias
          end
        end

        def replace_aliased_region_subtags(locale)
          region = locale.region ? locale.region.to_sym : nil
          if found_alias = region_aliases[region]
            locale.region = found_alias
          end
        end

        def remove_placeholder_tags(locale)
          locale.script = nil if locale.script == 'Zzzz'
          locale.region = nil if locale.region == 'ZZ'
          locale.language ||= 'und'
        end

        def languages
          @languages ||= [:regular, :special].flat_map do |type|
            validity_resource[:languages][type]
          end
        end

        def scripts
          @scripts ||= [:regular, :special].flat_map do |type|
            validity_resource[:scripts][type]
          end
        end

        def territories
          @territories ||= [:regular, :special, :macroregion].flat_map do |type|
            validity_resource[:regions][type]
          end
        end

        def variants
          validity_resource[:variants][:regular]
        end

        def aliases_resource
          @aliases_resource ||=
            TwitterCldr.get_resource('shared', 'aliases')[:aliases]
        end

        def validity_resource
          @validity_resource ||=
            TwitterCldr.get_resource('shared', 'validity_data')[:validity_data]
        end

        def parent_locales
          @parent_locales ||= TwitterCldr.get_resource('shared', 'parent_locales')
        end
      end

      attr_accessor :language, :script, :region, :variants

      def initialize(language, script = nil, region = nil, variants = [])
        @language = language ? language.to_s : nil
        @script = script ? script.to_s : nil
        @region = region ? region.to_s : nil
        @variants = Array(variants)
      end

      def full_script
        # fall back to abbreviated script if long alias can't be found
        @full_script ||= PropertyValueAliases.long_alias_for('sc', script) || script
      end

      def abbreviated_script
        @short_script ||= PropertyValueAliases.abbreviated_alias_for('sc', script) || script
      end

      def maximize
        LikelySubtags.locale_for(to_s)
      end

      def max_supported
        @max_supported ||= maximize.supported
      end

      def supported
        @supported ||= begin
          ancestor_chain.sort.find do |loc|
            TwitterCldr.supported_locale?(loc.dasherized)
          end
        end
      end

      def dasherized
        join('-')
      end

      def join(delimiter = '_')
        to_a.join(delimiter)
      end

      alias :underscored :join
      alias :to_s :join

      def to_a
        ([language, script, region] + variants).compact
      end

      def permutations(delimiter = '_')
        perms = [
          [language, script, region].compact.join(delimiter),
          [language, script].compact.join(delimiter),
          [language, region].compact.join(delimiter),
          language,
        ]

        perms.uniq
      end

      def ==(other)
        language == other.language &&
          script == other.script &&
          region == other.region &&
          variants == other.variants
      end

      alias eql? ==

      def hash
        to_a.hash
      end

      def sort_key
        k = 0
        k += 3 if language
        k += 2 if script
        k += 1 if region
        k
      end

      def <=>(other)
        other.sort_key <=> sort_key
      end

      def ancestor_chain
        ancestry = [self]
        remaining = [self]

        until remaining.empty?
          locale = remaining.pop

          if parent = self.class.send(:parent_locales)[locale.to_s]
            parent = self.class.parse(parent)
            ancestry << parent
            remaining << parent
          else
            parents = locale.permutations.map { |p| self.class.parse(p) }
            remaining += parents - ancestry
            ancestry += parents - ancestry
          end
        end

        ancestry
      end

    end
  end
end
