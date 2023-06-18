# frozen_string_literal: true

module PdfIcons
  PATH = Rails.root.join('lib/pdf_icons')

  WIDTH = 240
  HEIGHT = 240

  module_function

  def check_io
    @check_io ||= StringIO.new(PATH.join('check.png').read)
  end

  def paperclip_io
    @paperclip_io ||= StringIO.new(PATH.join('paperclip.png').read)
  end
end
