# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'eprun'

module TwitterCldr
  module Normalization

    VALID_NORMALIZERS  = [:nfd, :nfkd, :nfc, :nfkc]
    DEFAULT_NORMALIZER = :nfd

    class << self

      def normalize(string, options = {})
        validate_form(form = extract_form_from(options))
        Eprun.normalize(string, form)
      end

      def normalized?(string, options = {})
        validate_form(form = extract_form_from(options))
        Eprun.normalized?(string, form)
      end

      private

      def extract_form_from(options)
        options.fetch(:using, DEFAULT_NORMALIZER).to_s.downcase.to_sym
      end

      def validate_form(form)
        unless VALID_NORMALIZERS.include?(form)
          raise ArgumentError.new("#{form.inspect} is not a valid normalizer "\
            "(valid normalizers are #{VALID_NORMALIZERS.join(', ')})")
        end
      end

    end
  end
end
