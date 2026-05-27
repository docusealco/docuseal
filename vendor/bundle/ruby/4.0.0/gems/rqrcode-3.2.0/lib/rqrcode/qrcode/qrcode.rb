# frozen_string_literal: true

require "forwardable"

module RQRCode # :nodoc:
  class QRCode
    extend Forwardable

    def_delegators :@qrcode, :to_s
    def_delegators :@qrcode, :modules # deprecated

    attr_reader :qrcode

    def initialize(string, *args)
      @qrcode = RQRCodeCore::QRCode.new(string, *args)
    end
  end
end
