# frozen_string_literal: true

RSpec.describe 'Template Share Link' do
  let!(:account) { create(:account) }
  let!(:author) { create(:user, account:) }
  let!(:template) { create(:template, account:, author:) }

  before do
    sign_in(author)
  end

  context 'when the template is not shareable' do
    before do
      visit template_path(template)
    end

    it 'makes the template shareable' do
      click_on 'Link'

      expect do
        within '#modal' do
          check 'template_shared_link'
        end
      end.to change { template.reload.shared_link }.from(false).to(true)
    end

    it 'makes the template shareable on toggle' do
      click_on 'Link'

      expect do
        within '#modal' do
          find('#template_shared_link').click
        end
      end.to change { template.reload.shared_link }.from(false).to(true)
    end
  end

  context 'when the template is already shareable' do
    before do
      template.update(shared_link: true)
      visit template_path(template)
    end

    it 'makes the template unshareable' do
      click_on 'Link'

      expect do
        within '#modal' do
          uncheck 'template_shared_link'
        end
      end.to change { template.reload.shared_link }.from(true).to(false)
    end
  end
end
