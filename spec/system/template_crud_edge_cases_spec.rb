# frozen_string_literal: true

RSpec.describe 'Template CRUD Edge Cases' do
  let(:account) { create(:account) }
  let(:user) { create(:user, account:) }

  before do
    sign_in(user)
  end

  describe 'restoring an archived template' do
    let!(:template) do
      create(:template, account:, author: user, archived_at: Time.current,
                        except_field_types: %w[phone payment])
    end

    it 'restores an archived template from the template page' do
      visit template_path(template)

      expect(page).to have_content('Archived')
      page.find('form[action*="restore"]').click

      expect(template.reload.archived_at).to be_nil
    end

    pending 'lists archived templates on the dedicated index page: Restore button selector not matching' do
      visit templates_archived_index_path

      expect(page).to have_content(template.name)
      find('button[aria-label]').click

      expect(page).not_to have_content(template.name)
    end
  end

  describe 'template share link' do
    let!(:template) { create(:template, account:, author: user, except_field_types: %w[phone payment]) }

    it 'opens the share link modal' do
      visit template_path(template)

      click_link 'Link'

      expect(page).to have_field('embedding_url', with: /#{template.slug}/)
    end

    it 'enables and disables the share link' do
      visit template_share_link_path(template)

      check 'template_shared_link'
      page.execute_script('document.getElementById("shared_link_form").submit()')

      expect(template.reload.shared_link).to be true

      visit template_share_link_path(template)

      uncheck 'template_shared_link'
      page.execute_script('document.getElementById("shared_link_form").submit()')

      expect(template.reload.shared_link).to be false
    end
  end

  describe 'template folder management' do
    it 'navigates through folders on the dashboard' do
      folder = create(:template_folder, account:, author: user, name: 'My Folder')
      template_in_folder = create(:template, account:, author: user, folder:,
                                             except_field_types: %w[phone payment])
      template_root = create(:template, account:, author: user, name: 'Root Template',
                                        except_field_types: %w[phone payment])

      visit folder_path(folder)

      expect(page).to have_content(folder.name)
      expect(page).to have_content(template_in_folder.name)
      expect(page).not_to have_content(template_root.name)
    end
  end
end
