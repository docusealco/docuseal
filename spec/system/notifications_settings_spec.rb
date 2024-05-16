# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Notifications Settings' do
  let(:user) { create(:user, account: create(:account)) }

  before do
    sign_in(user)
  end

  it 'shows the notifications settings page' do
    visit settings_notifications_path

    expect(page).to have_content('Email Notifications')
    expect(page).to have_content('Receive notification emails on completed submission')
    expect(page).to have_content('Sign Request Email Reminders')

    expect(page).to have_field('account_config[value]')
    expect(page).to have_field('user_config[value]')
    %w[first_duration second_duration third_duration].each do |duration|
      expect(page).to have_field("account_config[value][#{duration}]")
    end
  end

  context 'when changes email notifications settings' do
    it 'updates BCC email address' do
      visit settings_notifications_path

      fill_in 'account_config[value]', with: 'john.doe@example.com'

      all(:button, 'Save')[0].click

      expect(page).to have_content('Changes have been saved')

      account_config = AccountConfig.find_by(account: user.account, key: AccountConfig::BCC_EMAILS)

      expect(account_config.value).to eq('john.doe@example.com')
    end

    it 'delete BCC email address' do
      create(:account_config, account: user.account, key: AccountConfig::BCC_EMAILS, value: 'john.doe.bbc@example.com')

      visit settings_notifications_path

      expect(page).to have_field('account_config[value]', with: 'john.doe.bbc@example.com')

      fill_in 'account_config[value]', with: ''

      all(:button, 'Save')[0].click

      expect(page).to have_content('Changes have been saved')
    end

    it 'disable receive notification emails on completed submission' do
      visit settings_notifications_path

      uncheck 'user_config[value]'

      expect(UserConfig.find_by(user:, key: UserConfig::RECEIVE_COMPLETED_EMAIL).value).to be false
    end

    it 'enable receive notification emails on completed submission' do
      create(:user_config, user:, key: UserConfig::RECEIVE_COMPLETED_EMAIL, value: false)

      visit settings_notifications_path

      check 'user_config[value]'

      expect(UserConfig.find_by(user:, key: UserConfig::RECEIVE_COMPLETED_EMAIL).value).to be true
    end
  end

  context 'when changes sign request email reminders settings' do
    it 'updates first reminder duration' do
      visit settings_notifications_path

      selected_values = %w[first_duration second_duration third_duration].index_with do |_|
        AccountConfigs::REMINDER_DURATIONS.keys.sample
      end

      selected_values.each do |duration, value|
        selected_duration_name = AccountConfigs::REMINDER_DURATIONS[value]
        select selected_duration_name, from: "account_config[value][#{duration}]"
      end

      expect do
        all(:button, 'Save')[1].click
      end.to change(AccountConfig, :count).by(1)

      account_config = AccountConfig.find_by(account: user.account, key: AccountConfig::SUBMITTER_REMINDERS)

      expect(page).to have_content('Changes have been saved')

      selected_values.each do |duration, value|
        expect(account_config.value[duration]).to eq(value)
      end
    end
  end
end
