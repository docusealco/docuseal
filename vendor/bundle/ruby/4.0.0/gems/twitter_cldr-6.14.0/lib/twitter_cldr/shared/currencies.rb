# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Shared
    module Currencies
      class << self
        def currency_codes(locale = :en)
          resource(locale).keys.map { |c| c.to_s }
        end

        def for_code(currency_code, locale = :en)
          currency_code = currency_code.to_sym
          data = resource(locale)[currency_code]
          symbol_data = iso_currency_symbols[currency_code]

          if data
            result = {
              currency:    currency_code,
              name:        data[:name],
              cldr_symbol: data[:symbol] || currency_code.to_s,
              symbol:      data[:symbol] || currency_code.to_s,
              code_points: (data[:symbol] || currency_code.to_s).unpack("U*")
            }

            result.merge!(symbol_data) if symbol_data
          end

          result
        end

        private

        # ISO 4217 to be precise
        def iso_currency_symbols
          @iso_currency_symbols ||= TwitterCldr.get_resource(:shared, :iso_currency_symbols)
        end

        def resource(locale)
          locale = locale.to_sym
          @resource ||= {}
          @resource[locale] ||= TwitterCldr.get_resource(:locales, locale, :currencies)[locale][:currencies]
        end
      end
    end
  end
end
