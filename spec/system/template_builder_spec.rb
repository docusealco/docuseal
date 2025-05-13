# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Template Builder' do
  let(:account) { create(:account) }
  let(:author) { create(:user, account:) }
  let(:template) { create(:template, account:, author:, attachment_count: 3, except_field_types: %w[phone payment]) }

  before do
    sign_in(author)
  end

  context 'when manage template documents' do
    before do
      visit edit_template_path(template)
    end

    it 'replaces the document' do
      doc = find("div[id='documents_container'] div[data-document-uuid='#{template.schema[1]['attachment_uuid']}'")
      doc.click

      expect do
        wait_for_fetch do
          doc.find('.replace-document-button').click
          doc.find('.replace-document-button input[type="file"]', visible: false)
             .attach_file(Rails.root.join('spec/fixtures/sample-image.png'))
        end
      end.to change { template.documents.count }.by(1)

      expect(template.reload['schema'][1]['name']).to eq('sample-image')
    end
  end
end
