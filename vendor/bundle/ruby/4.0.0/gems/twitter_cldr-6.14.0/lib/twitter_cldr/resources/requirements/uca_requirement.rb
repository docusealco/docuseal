# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'open-uri'
require 'fileutils'

module TwitterCldr
  module Resources
    module Requirements

      class UcaRequirement < UnicodeRequirement
        UNICODE_UCA_URL = "https://unicode.org/Public/UCA/%{version}".freeze

        def url
          UNICODE_UCA_URL
        end
      end

    end
  end
end
