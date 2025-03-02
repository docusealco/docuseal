# frozen_string_literal: true

module TextUtils
  RTL_REGEXP = /[\p{Hebrew}\p{Arabic}]/
  MASK_REGEXP = /[^\s\-_\[\]\(\)\+\?\.\,]/
  MASK_SYMBOL = 'X'

  module_function

  def rtl?(text)
    return false if text.blank?

    text.match?(TextUtils::RTL_REGEXP)
  rescue Encoding::CompatibilityError
    false
  end

  def mask_value(text)
    text.to_s.gsub(MASK_REGEXP, MASK_SYMBOL)
  end

  def maybe_rtl_reverse(text)
    if text.match?(RTL_REGEXP)
      TwitterCldr::Shared::Bidi
        .from_string(ArabicLetterConnector.transform(text), direction: :RTL)
        .reorder_visually!.to_s
    else
      text
    end
  end
end
