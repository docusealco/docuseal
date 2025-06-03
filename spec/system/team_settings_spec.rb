# frozen_string_literal: true

RSpec.describe 'Team Settings' do
  let(:account) { create(:account) }
  let(:second_account) { create(:account) }
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

    it 'shows only active users' do
      within '.table' do
        users.each do |user|
          expect(page).to have_content(user.full_name)
          expect(page).to have_content(user.email)
          expect(page).to have_link('Edit', href: edit_user_path(user))
        end

        expect(page).to have_button('Remove')
        expect(page).to have_no_button('Unarchive')

        expect(page).to have_no_content(other_user.full_name)
        expect(page).to have_no_content(other_user.email)
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

    it "doesn't create a new user if a user already exists" do
      click_link 'New User'

      within '#modal' do
        fill_in 'First name', with: 'Michael'
        fill_in 'Last name', with: 'Jordan'
        fill_in 'Email', with: users.first.email
        fill_in 'Password', with: 'password'

        expect do
          click_button 'Submit'
        end.not_to change(User, :count)
      end

      expect(page).to have_content('Email already exists')
    end

    it "doesn't create a new user if a user belongs to another account" do
      user = create(:user, account: second_account)
      visit settings_users_path

      click_link 'New User'

      within '#modal' do
        fill_in 'First name', with: 'Michael'
        fill_in 'Last name', with: 'Jordan'
        fill_in 'Email', with: user.email
        fill_in 'Password', with: 'password'

        expect do
          click_button 'Submit'
        end.not_to change(User, :count)

        expect(page).to have_content('Email has already been taken')
      end
    end

    it 'does not allow to create a new user with an invalid email' do
      click_link 'New User'

      within '#modal' do
        fill_in 'First name', with: 'Joseph'
        fill_in 'Last name', with: 'Smith'
        fill_in 'Email', with: 'joseph.smith@gmail'
        fill_in 'Password', with: 'password'

        expect do
          click_button 'Submit'
        end.not_to change(User, :count)

        expect(page).to have_content('Email is invalid')
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
          first(:button, 'Remove').click
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

  context 'when some users are archived' do
    let!(:users) { create_list(:user, 2, account:) }
    let!(:archived_users) { create_list(:user, 2, account:, archived_at: Time.current) }
    let!(:other_user) { create(:user) }

    it 'shows only active users' do
      visit settings_users_path

      within '.table' do
        users.each do |user|
          expect(page).to have_content(user.full_name)
          expect(page).to have_content(user.email)
        end

        archived_users.each do |user|
          expect(page).to have_no_content(user.full_name)
          expect(page).to have_no_content(user.email)
        end

        expect(page).to have_no_content(other_user.full_name)
        expect(page).to have_no_content(other_user.email)
      end

      expect(page).to have_link('View Archived', href: settings_archived_users_path)
    end

    it 'shows only archived users' do
      visit settings_archived_users_path

      within '.table' do
        archived_users.each do |user|
          expect(page).to have_content(user.full_name)
          expect(page).to have_content(user.email)
          expect(page).to have_no_link('Edit', href: edit_user_path(user))
        end

        users.each do |user|
          expect(page).to have_no_content(user.full_name)
          expect(page).to have_no_content(user.email)
          expect(page).to have_no_link('Edit', href: edit_user_path(user))
        end

        expect(page).to have_button('Unarchive')
        expect(page).to have_no_button('Remove')

        expect(page).to have_no_content(other_user.full_name)
        expect(page).to have_no_content(other_user.email)
      end

      expect(page).to have_content('Archived Users')
      expect(page).to have_link('View Active', href: settings_users_path)
    end
  end
end
