# frozen_string_literal: true

RSpec.describe 'Role-based access' do
  let(:account) { create(:account) }

  describe 'admin role' do
    let(:admin) { create(:user, account:, role: User::ADMIN_ROLE) }

    before do
      sign_in(admin)
    end

    it 'shows Create and Upload buttons on the dashboard' do
      visit templates_path

      expect(page).to have_link('Create')
      expect(page).to have_content(I18n.t('upload'))
    end

    it 'shows all settings nav items' do
      visit settings_personalization_path

      within('#account_settings_menu') do
        expect(page).to have_link(I18n.t('personalization'))
        expect(page).to have_link(I18n.t('users'))
        expect(page).to have_link(I18n.t('notifications'))
        expect(page).to have_link(I18n.t('e_signature'))
      end
    end

    it 'shows Edit, Clone, and Archive on a template' do
      template = create(:template, account:, author: admin)

      visit template_path(template)

      expect(page).to have_content(template.name)
      expect(page).to have_link('Edit')
      expect(page).to have_link('Clone')
      expect(page).to have_button('Archive')
    end
  end

  describe 'editor role' do
    let(:editor) { create(:user, account:, role: User::EDITOR_ROLE) }

    before do
      sign_in(editor)
    end

    it 'shows Create and Upload buttons on the dashboard' do
      visit templates_path

      expect(page).to have_link('Create')
      expect(page).to have_content(I18n.t('upload'))
    end

    it 'shows the Users nav item' do
      visit settings_personalization_path

      within('#account_settings_menu') do
        expect(page).to have_link(I18n.t('users'))
      end
    end

    it 'shows limited settings nav items (no email/esign)' do
      visit settings_personalization_path

      within('#account_settings_menu') do
        expect(page).to have_link(I18n.t('personalization'))
        expect(page).to have_link(I18n.t('notifications'))
        expect(page).to have_link(I18n.t('users'))

        expect(page).not_to have_link(I18n.t('e_signature'))
      end
    end

    it 'shows Edit, Clone, and Archive on a template' do
      template = create(:template, account:, author: editor)

      visit template_path(template)

      expect(page).to have_content(template.name)
      expect(page).to have_link('Edit')
      expect(page).to have_link('Clone')
      expect(page).to have_button('Archive')
    end

    it 'can view personalization but cannot modify brand_name' do
      visit settings_personalization_path

      expect(page).to have_field('brand_name')

      fill_in 'brand_name', with: 'Editor Brand'
      click_button 'Save'

      expect(account.reload.brand_name).not_to eq('Editor Brand')
    end
  end

  describe 'viewer role' do
    let(:viewer) { create(:user, account:, role: User::VIEWER_ROLE) }

    before do
      sign_in(viewer)
    end

    it 'does NOT show Create or Upload buttons on the dashboard' do
      visit templates_path

      expect(page).not_to have_link('Create')
    end

    it 'does not have access to users settings' do
      visit settings_users_path

      expect(current_path).to eq(root_path)
    end

    it 'shows personalization and notifications in nav' do
      visit settings_personalization_path

      within('#account_settings_menu') do
        expect(page).to have_link(I18n.t('personalization'))
        expect(page).to have_link(I18n.t('notifications'))
      end
    end

    it 'can view a template but does not see Edit, Clone, or Archive' do
      template = create(:template, account:, author: create(:user, account:))

      visit template_path(template)

      expect(page).to have_content(template.name)
      expect(page).not_to have_link('Edit')
      expect(page).not_to have_link('Clone')
      expect(page).not_to have_button('Archive')
    end

    it 'can view personalization page but cannot modify brand_name' do
      visit settings_personalization_path

      expect(page).to have_field('brand_name')

      fill_in 'brand_name', with: 'Viewer Brand'
      click_button 'Save'

      expect(account.reload.brand_name).not_to eq('Viewer Brand')
    end
  end
end
