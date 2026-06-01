# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Formatters
    class CurrencyFormatter < NumberFormatter

      def format(tokens, number, options = {})
        options[:currency] ||= "USD"
        options[:locale] ||= :en
        currency = TwitterCldr::Shared::Currencies.for_code(options[:currency], options[:locale])
        currency ||= {
          currency:    options[:currency],
          symbol:      options[:currency],
          cldr_symbol: options[:currency]
        }

        # overwrite with explicit symbol if given
        currency[:symbol] = options[:symbol] if options[:symbol]

        digits_and_rounding = resource(options[:currency])
        options[:precision] ||= digits_and_rounding[:digits]
        options[:rounding] ||= digits_and_rounding[:rounding]

        symbol = options[:use_cldr_symbol] ? currency[:cldr_symbol] : currency[:symbol]
        symbol ||= currency[:currency].to_s
        super.gsub('¤', symbol)
      end

      private

      def resource(code)
        @resource ||= TwitterCldr.get_resource(:shared, :currency_digits_and_rounding)
        @resource[code.to_sym] || @resource[:DEFAULT]
      end

    end
  end
end
