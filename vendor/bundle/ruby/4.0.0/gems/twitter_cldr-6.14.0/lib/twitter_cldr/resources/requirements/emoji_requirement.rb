# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'open-uri'
require 'fileutils'

module TwitterCldr
  module Resources
    module Requirements

      class EmojiRequirement < UnicodeRequirement
        UNICODE_EMOJI_URL = "https://unicode.org/Public/emoji/%{version}".freeze

        def url
          UNICODE_EMOJI_URL
        end
      end

    end
  end
end
