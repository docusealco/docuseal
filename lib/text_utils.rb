# frozen_string_literal: true

module TextUtils
  RTL_REGEXP = /[\p{Hebrew}\p{Arabic}]/

  module_function

  def rtl?(text)
    return false if text.blank?

    text.match?(TextUtils::RTL_REGEXP)
  rescue Encoding::CompatibilityError
    false
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
