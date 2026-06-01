# encoding: utf-8
# frozen_string_literal: true

module Mail
  # keywords        =       "Keywords:" phrase *("," phrase) CRLF
  class KeywordsField < NamedStructuredField #:nodoc:
    NAME = 'Keywords'

    def element
      @element ||= PhraseList.new(value)
    end

    def keywords
      element.phrases
    end

    def default
      keywords
    end

    private
      def do_decode
        keywords.join(', ')
      end

      def do_encode
        "#{name}: #{keywords.join(",\r\n ")}\r\n"
      end
  end
end
