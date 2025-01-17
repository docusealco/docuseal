# frozen_string_literal: true

module NumberUtils
  FORMAT_LOCALES = {
    'dot' => 'de',
    'space' => 'fr',
    'comma' => 'en',
    'usd' => 'en',
    'eur' => 'fr',
    'gbp' => 'en'
  }.freeze

  CURRENCY_SYMBOLS = {
    'usd' => '$',
    'eur' => '€',
    'gbp' => '£'
  }.freeze

  module_function

  def format_number(number, format)
    locale = FORMAT_LOCALES[format]

    if CURRENCY_SYMBOLS[format]
      ApplicationController.helpers.number_to_currency(number, locale:, precision: 2, unit: CURRENCY_SYMBOLS[format])
    elsif locale
      ApplicationController.helpers.number_with_delimiter(number, locale:)
    else
      number
    end
  end
end
