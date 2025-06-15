# frozen_string_literal: true

module TextUtils
  RTL_REGEXP = /[\p{Hebrew}\p{Arabic}]/
  MASK_REGEXP = /[^\s\-_\[\]\(\)\+\?\.\,]/
  MASK_SYMBOL = 'X'

  TRANSLITERATIONS =
    I18n::Backend::Transliterator::HashTransliterator::DEFAULT_APPROXIMATIONS.reject { |_, v| v.length > 1 }

  TRANSLITERATION_REGEXP = Regexp.union(TRANSLITERATIONS.keys)

  module_function

  def rtl?(text)
    return false if text.blank?

    text.match?(TextUtils::RTL_REGEXP)
  rescue Encoding::CompatibilityError
    false
  end

  def transliterate(text)
    text.to_s.gsub(TRANSLITERATION_REGEXP) { |e| TRANSLITERATIONS[e] }
  end

  def mask_value(text, unmask_size = 0)
    if unmask_size.is_a?(Numeric) && !unmask_size.zero? && unmask_size.abs < text.length
      if unmask_size.negative?
        [
          text.first(text.length + unmask_size).gsub(MASK_REGEXP, MASK_SYMBOL),
          text.last(-unmask_size)
        ].join
      elsif unmask_size.positive?
        [
          text.first(unmask_size),
          text.last(text.length - unmask_size).gsub(MASK_REGEXP, MASK_SYMBOL)
        ].join
      end
    else
      text.to_s.gsub(MASK_REGEXP, MASK_SYMBOL)
    end
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
