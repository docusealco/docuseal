# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Team Settings' do
  let(:account) { create(:account) }
  let(:current_user) { create(:user, account:) }

  before do
    sign_in(current_user)
  end

  context 'when multiple users' do
    let!(:users) { create_list(:user, 2, account:) }
    let!(:other_user) { create(:user) }

    before do
      visit settings_users_path
    end

    it 'shows all users' do
      within '.table' do
        users.each do |user|
          expect(page).to have_content(user.full_name)
          expect(page).to have_content(user.email)
          expect(page).to have_no_content(other_user.email)
        end
      end
    end

    it 'creates a new user' do
      click_link 'New User'

      within '#modal' do
        fill_in 'First name', with: 'Joseph'
        fill_in 'Last name', with: 'Smith'
        fill_in 'Email', with: 'joseph.smith@example.com'
        fill_in 'Password', with: 'password'

        expect do
          click_button 'Submit'
        end.to change(User, :count).by(1)

        user = User.last

        expect(user.first_name).to eq('Joseph')
        expect(user.last_name).to eq('Smith')
        expect(user.email).to eq('joseph.smith@example.com')
        expect(user.account).to eq(account)
      end
    end

    it 'updates a user' do
      first(:link, 'Edit').click

      fill_in 'First name', with: 'Adam'
      fill_in 'Last name', with: 'Meier'
      fill_in 'Email', with: 'adam.meier@example.com'
      fill_in 'Password', with: 'new_password'

      expect do
        click_button 'Submit'
      end.not_to change(User, :count)

      user = User.find_by(email: 'adam.meier@example.com')

      expect(user.first_name).to eq('Adam')
      expect(user.last_name).to eq('Meier')
      expect(user.email).to eq('adam.meier@example.com')
    end

    it 'removes a user' do
      expect do
        accept_confirm('Are you sure?') do
          first(:button, 'Delete').click
        end
      end.to change { User.active.count }.by(-1)

      expect(page).to have_content('User has been removed')
    end
  end

  context 'when single user' do
    before do
      visit settings_users_path
    end

    it 'does not allow to remove the current user' do
      expect(page).to have_no_content('User has been removed')
    end
  end
end
