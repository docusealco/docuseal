# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountLogo do
  describe '.sanitize_svg' do
    it 'removes <script> elements' do
      svg = <<~SVG
        <svg xmlns="http://www.w3.org/2000/svg">
          <script>alert(1)</script>
          <rect width="10" height="10" />
        </svg>
      SVG

      cleaned = described_class.sanitize_svg(svg)

      expect(cleaned).not_to include('<script')
      expect(cleaned).not_to include('alert(1)')
      expect(cleaned).to include('<rect')
    end

    it 'strips on* event-handler attributes' do
      svg = '<svg xmlns="http://www.w3.org/2000/svg"><rect onload="bad()" onclick="hax()" width="1" height="1"/></svg>'

      cleaned = described_class.sanitize_svg(svg)

      expect(cleaned).not_to include('onload')
      expect(cleaned).not_to include('onclick')
      expect(cleaned).not_to include('bad()')
      expect(cleaned).not_to include('hax()')
    end

    it 'removes <foreignObject> elements' do
      svg = '<svg xmlns="http://www.w3.org/2000/svg"><foreignObject><body>malicious</body></foreignObject></svg>'

      cleaned = described_class.sanitize_svg(svg)

      expect(cleaned).not_to match(/foreignObject/i)
    end

    it 'drops external href / xlink:href but keeps in-doc fragments and data: URIs' do
      svg = <<~SVG
        <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
          <a href="https://attacker.example"><rect width="1" height="1"/></a>
          <use xlink:href="#circle" />
          <image xlink:href="data:image/png;base64,iVBOR" />
        </svg>
      SVG

      cleaned = described_class.sanitize_svg(svg)

      expect(cleaned).not_to include('https://attacker.example')
      expect(cleaned).to include('#circle')
      expect(cleaned).to include('data:image/png')
    end
  end

  describe '.sanitize_upload' do
    it 'returns the original tempfile for PNG uploads' do
      png_bytes = Rails.public_path.join('favicon-32x32.png').binread
      file = ActionDispatch::Http::UploadedFile.new(
        tempfile: Tempfile.new(['logo', '.png']).tap do |t|
          t.binmode
          t.write(png_bytes)
          t.rewind
        end,
        filename: 'logo.png', type: 'image/png'
      )

      result = described_class.sanitize_upload(file)

      expect(result.content_type).to eq('image/png')
      expect(result.filename).to eq('logo.png')
    end

    it 'sanitises SVG content and returns a StringIO with cleaned bytes' do
      svg = '<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script><rect/></svg>'
      file = ActionDispatch::Http::UploadedFile.new(
        tempfile: Tempfile.new(['logo', '.svg']).tap do |t|
          t.write(svg)
          t.rewind
        end,
        filename: 'logo.svg', type: 'image/svg+xml'
      )

      result = described_class.sanitize_upload(file)

      expect(result.content_type).to eq('image/svg+xml')
      body = result.io.read
      expect(body).not_to include('<script')
      expect(body).not_to include('alert(1)')
      expect(body).to include('<rect')
    end
  end
end
