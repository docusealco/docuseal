# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard Page' do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }

  before do
    sign_in(user)
  end

  context 'when are no templates' do
    it 'shows empty state' do
      visit root_path

      expect(page).to have_link('Create', href: new_template_path)
    end
  end

  context 'when there are templates' do
    let!(:authors) { create_list(:user, 5, account:) }
    let!(:templates) { authors.map { |author| create(:template, account:, author:) } }
    let!(:other_template) { create(:template, account: create(:user).account) }

    before do
      visit root_path
    end

    it 'shows the list of templates' do
      templates.each do |template|
        expect(page).to have_content(template.name)
        expect(page).to have_content(template.author.full_name)
      end

      expect(page).to have_content('Templates')
      expect(page).to have_no_content(other_template.name)
      expect(page).to have_link('Create', href: new_template_path)
    end

    it 'initializes the template creation process' do
      click_link 'Create'

      within('#modal') do
        fill_in 'template[name]', with: 'New Template'

        expect do
          click_button 'Create'
        end.to change(Template, :count).by(1)

        expect(page).to have_current_path(edit_template_path(Template.last), ignore_query: true)
      end
    end
  end
end
