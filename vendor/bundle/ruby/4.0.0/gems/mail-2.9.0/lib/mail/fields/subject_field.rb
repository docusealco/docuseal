# encoding: utf-8
# frozen_string_literal: true

module Mail
  #
  # subject         =       "Subject:" unstructured CRLF
  class SubjectField < NamedUnstructuredField #:nodoc:
    NAME = 'Subject'

    def self.singular?
      true
    end
  end
end
