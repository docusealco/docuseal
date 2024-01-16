# frozen_string_literal: true

module Submitters
  module ValidateSending
    InvalidEmail = Class.new(StandardError)

    module_function

    def call(submitter, _mail)
      raise InvalidEmail unless submitter.email.to_s.include?('@')

      true
    end
  end
end
