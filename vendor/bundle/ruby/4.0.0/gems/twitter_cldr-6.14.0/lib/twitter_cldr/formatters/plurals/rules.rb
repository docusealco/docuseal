# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'cldr-plurals/ruby_runtime'

module TwitterCldr
  module Formatters
    module Plurals
      module Rules

        class << self

          DEFAULT_TYPE = :cardinal

          def all(type = DEFAULT_TYPE)
            all_for(TwitterCldr.locale, type)
          end

          def all_for(locale, type = DEFAULT_TYPE)
            names(locale, type)
          end

          def rule_for(number, locale = TwitterCldr.locale, type = DEFAULT_TYPE)
            rule(locale, type).call(number.to_s, CldrPlurals::RubyRuntime)
          rescue
            :other
          end

          protected

          def get_resource(locale)
            locale = TwitterCldr.convert_locale(locale)
            cache_key = TwitterCldr::Utils.compute_cache_key(locale)
            locale_cache[cache_key] ||= begin
              rsrc = TwitterCldr.get_locale_resource(locale, :plurals)[locale]
              rsrc.inject({}) do |ret, (rule_type, rule_data)|
                ret[rule_type] = rule_data.merge(rule: eval(rule_data[:rule]))
                ret
              end
            end
          end

          def rule(locale, type)
            get_resource(locale)[type][:rule]
          end

          def names(locale, type)
            get_resource(locale)[type][:names]
          end

          def locale_cache
            @locale_cache ||= {}
          end

        end

      end
    end
  end
end
