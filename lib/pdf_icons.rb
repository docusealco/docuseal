# frozen_string_literal: true

module PdfIcons
  PATH = Rails.root.join('lib/pdf_icons')

  WIDTH = 240
  HEIGHT = 240

  module_function

  def check_io
    StringIO.new(check_data)
  end

  def paperclip_io
    StringIO.new(paperclip_data)
  end

  def logo_io
    StringIO.new(logo_data)
  end

  def logo_new_io
    StringIO.new(logo_new_data)
  end

  def check_data
    @check_data ||= PATH.join('check.png').read
  end

  def paperclip_data
    @paperclip_data ||= PATH.join('paperclip.png').read
  end

  def logo_data
    @logo_data ||= PATH.join('logo.png').read
  end

  def logo_new_data
    @logo_new_data ||= PATH.join('logo_new.png').read
  end
end
