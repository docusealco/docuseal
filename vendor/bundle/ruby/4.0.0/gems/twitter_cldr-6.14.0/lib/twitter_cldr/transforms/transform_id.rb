# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Transforms

    class InvalidTransformIdError < StandardError; end

    class TransformId
      CHAIN = [
        :normal_fallback1, :normal_fallback2, :laddered_fallback1,
        :normal_fallback3, :laddered_fallback2
      ]

      class << self
        def find(source_locale_or_str, target_locale_or_str)
          source_locale = parse_locale(source_locale_or_str)
          target_locale = parse_locale(target_locale_or_str)
          source_chain = map_chain_for(source_locale)
          target_chain = map_chain_for(target_locale)
          variants = variants_for(source_locale, target_locale)

          # add original locale strings to chain in case they aren't actually
          # locales (think 'hiragana', etc)
          source_chain << [source_locale_or_str.to_s]
          target_chain << [target_locale_or_str.to_s]

          find_in_chains(
            source_chain, target_chain, variants
          )
        end

        def parse(str)
          if normalized = normalize(str)
            new(*split(normalized))
          else
            raise InvalidTransformIdError,
              "'#{str}' is not a valid transform id"
          end
        end

        def split(str)
          str.split(/[\-\/]/)
        end

        def join(source, target, variant = nil)
          base = "#{source}-#{target}"
          variant ? "#{base}/#{variant}" : base
        end

        def join_file_name(parts)
          parts.compact.join('-')
        end

        def transform_id_map
          @transform_id_map ||= TwitterCldr.get_resource(
            *%w(shared transforms transform_id_map)
          )
        end

        private

        def parse_locale(locale_or_str)
          case locale_or_str
            when TwitterCldr::Shared::Locale
              locale_or_str
            else
              TwitterCldr::Shared::Locale.parse(locale_or_str.to_s).maximize
          end
        end

        def normalize(str)
          source, target, variant = split(str)
          normalization_index[
            join(source, target, variant).downcase
          ]
        end

        def normalization_index
          @index ||=
            transform_id_map.each_with_object({}) do |(key, file), ret|
              source, target, variant = split(key)
              key = join(source, target, variant)
              reverse_key = join(target, source, variant)
              ret[key.downcase] = key
              ret[reverse_key.downcase] = reverse_key
            end
        end

        def find_in_chains(source_chain, target_chain, variants)
          variants.each do |variant|
            target_chain.each do |target|
              source_chain.each do |source|
                source_str = join_subtags(source, variant)
                target_str = join_subtags(target, variant)
                transform_id_str = join(source_str, target_str)

                if Transformer.exists?(transform_id_str)
                  return parse(transform_id_str)
                end
              end
            end
          end
          nil
        end

        def join_subtags(tags, variant)
          tags.join('_').tap do |result|
            result << "_#{variant}" if variant
          end
        end

        def variants_for(source_locale, target_locale)
          (source_locale.variants + target_locale.variants + [nil]).uniq
        end

        def map_chain_for(locale)
          CHAIN.map { |link| send(link, locale) }
        end

        def normal_fallback1(locale)
          [locale.language, locale.full_script, locale.region]
        end

        def normal_fallback2(locale)
          [locale.language, locale.full_script]
        end

        def normal_fallback3(locale)
          [locale.language]
        end

        def laddered_fallback1(locale)
          [locale.language, locale.region]
        end

        def laddered_fallback2(locale)
          [locale.full_script]
        end
      end

      attr_reader :source, :target, :variant

      def initialize(source, target, variant = nil)
        @source = source
        @target = target
        @variant = variant
      end

      def has_variant?
        !!variant
      end

      def reverse
        self.class.new(target, source, variant)
      end

      def file_name
        self.class.transform_id_map[to_s]
      end

      def to_s
        self.class.join(source, target, variant)
      end
    end

  end
end
