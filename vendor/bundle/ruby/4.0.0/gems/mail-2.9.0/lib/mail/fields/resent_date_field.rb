# encoding: utf-8
# frozen_string_literal: true

module Mail
  #
  # resent-date     =       "Resent-Date:" date-time CRLF
  class ResentDateField < CommonDateField #:nodoc:
    NAME = 'Resent-Date'
  end
end
