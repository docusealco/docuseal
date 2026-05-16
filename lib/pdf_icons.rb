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

  # Returns binary IO for the account's uploaded logo when attached,
  # otherwise the default WaboSign mark. SVG uploads are rasterised via
  # ActiveStorage variants (libvips + librsvg ship in the production image
  # via the `vips` Alpine package). On any failure path we fall back to the
  # default mark so audit-trail generation never crashes on a bad logo.
  def account_logo_io(account)
    return logo_io if account.nil? || !account.logo.attached?

    blob = account.logo
    if blob.content_type == 'image/svg+xml'
      variant = blob.variant(resize_to_limit: [WIDTH, HEIGHT], format: :png).processed
      StringIO.new(variant.download)
    else
      StringIO.new(blob.download)
    end
  rescue StandardError => e
    Rails.logger.warn("[PdfIcons] account_logo_io fallback for account=#{account&.id}: #{e.class}: #{e.message}")
    logo_io
  end

  def stamp_logo_io
    StringIO.new(stamp_logo_data)
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

  def stamp_logo_data
    @stamp_logo_data ||= PATH.join('stamp-logo.png').read
  end
end
