# frozen_string_literal: true

module NumberUtils
  FORMAT_LOCALES = {
    'dot' => 'de',
    'space' => 'fr',
    'comma' => 'en'
  }.freeze

  module_function

  def format_number(number, format)
    locale = FORMAT_LOCALES[format]

    if locale
      ApplicationController.helpers.number_with_delimiter(number, locale:)
    else
      number
    end
  end
end
