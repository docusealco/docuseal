# frozen_string_literal: true

class TemplatesShareLinkQrController < ApplicationController
  load_and_authorize_resource :template

  def show
    return render :disabled, layout: 'plain' unless @template.shared_link?

    shared_link_url = start_form_url(slug: @template.slug, host: form_link_host)

    @qr_svg_code = RQRCode::QRCode.new(shared_link_url, level: :m).as_svg(viewbox: true)

    @page_size =
      if TimeUtils.timezone_abbr(current_account.timezone, Time.current.beginning_of_year).in?(TimeUtils::US_TIMEZONES)
        'Letter'
      else
        'A4'
      end

    render :show, layout: false
  end
end
