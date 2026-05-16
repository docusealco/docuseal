# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Account logo', type: :request do
  let!(:account) { create(:account) }
  let!(:admin) { create(:user, account: account, email: 'admin@wabo.cc') }

  before { sign_in admin }

  def upload(content_type:, bytes:, filename: 'logo.png')
    tempfile = Tempfile.new(['logo', File.extname(filename)])
    tempfile.binmode
    tempfile.write(bytes)
    tempfile.rewind
    Rack::Test::UploadedFile.new(tempfile.path, content_type)
  end

  describe 'POST /settings/account_logo' do
    it 'accepts a PNG upload and attaches it to the current account' do
      png_bytes = File.binread(Rails.root.join('public/favicon-32x32.png'))

      expect do
        post settings_account_logo_path, params: { logo: upload(content_type: 'image/png', bytes: png_bytes) }
      end.to change { account.reload.logo.attached? }.from(false).to(true)

      expect(response).to redirect_to(settings_personalization_path)
      expect(flash[:notice]).to include('Logo updated')
    end

    it 'rejects an unsupported content type' do
      pdf_bytes = '%PDF-1.4 dummy'

      post settings_account_logo_path, params: { logo: upload(content_type: 'application/pdf', bytes: pdf_bytes, filename: 'logo.pdf') }

      expect(account.reload.logo.attached?).to be(false)
      expect(flash[:alert]).to include('PNG, JPEG, or SVG')
    end

    it 'rejects files over 2 MB' do
      big = SecureRandom.bytes(Account::LOGO_MAX_BYTES + 1)

      post settings_account_logo_path, params: { logo: upload(content_type: 'image/png', bytes: big) }

      expect(account.reload.logo.attached?).to be(false)
      expect(flash[:alert]).to include('under 2 MB')
    end

    it 'sanitises malicious SVG content before storing' do
      malicious = '<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script><rect onload="hax()" /></svg>'

      post settings_account_logo_path, params: { logo: upload(content_type: 'image/svg+xml', bytes: malicious, filename: 'logo.svg') }

      expect(account.reload.logo.attached?).to be(true)
      stored = account.logo.download
      expect(stored).not_to include('<script')
      expect(stored).not_to include('alert(1)')
      expect(stored).not_to include('onload')
      expect(stored).not_to include('hax()')
    end
  end

  describe 'DELETE /settings/account_logo' do
    it 'purges the attachment' do
      png_bytes = File.binread(Rails.root.join('public/favicon-32x32.png'))
      account.logo.attach(io: StringIO.new(png_bytes), filename: 'logo.png', content_type: 'image/png')
      expect(account.reload.logo.attached?).to be(true)

      delete settings_account_logo_path

      expect(account.reload.logo.attached?).to be(false)
      expect(response).to redirect_to(settings_personalization_path)
    end
  end
end
