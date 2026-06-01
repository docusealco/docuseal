# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Shared
    module Numbers

      class << self

        def symbols(locale = TwitterCldr.locale)
          get_resource(TwitterCldr.convert_locale(locale))[:symbols] rescue nil
        end

        private

        def get_resource(locale)
          TwitterCldr.get_locale_resource(locale, :numbers)[locale][:numbers]
        end

      end

    end
  end
end