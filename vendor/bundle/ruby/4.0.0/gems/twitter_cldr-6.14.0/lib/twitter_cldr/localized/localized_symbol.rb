# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Localized

    class LocalizedSymbol < LocalizedObject
      def as_language_code
        TwitterCldr::Shared::Languages.from_code_for_locale(@base_obj, @locale)
      end

      def as_locale
        TwitterCldr::Shared::Locale.parse(@base_obj.to_s)
      end

      def as_territory
        TwitterCldr::Shared::Territories::from_territory_code_for_locale(@base_obj, @locale)
      end

      def is_rtl?
        TwitterCldr::Shared::Languages.is_rtl?(@base_obj)
      end

      def formatter_const
        nil
      end
    end

  end
end
