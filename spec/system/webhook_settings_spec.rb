# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Webhook Settings' do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }

  before do
    sign_in(user)
  end

  it 'shows webhook settings page' do
    visit settings_webhooks_path

    expect(page).to have_content('Webhooks')
    expect(page).to have_field('Webhook URL')
    expect(page).to have_button('Save')

    WebhookUrl::EVENTS.each do |event|
      expect(page).to have_field(event, type: 'checkbox', disabled: true)
    end
  end

  it 'creates the webhook' do
    visit settings_webhooks_path

    fill_in 'Webhook URL', with: 'https://example.com/webhook'

    expect do
      click_button 'Save'
    end.to change(WebhookUrl, :count).by(1)

    webhook_url = account.webhook_urls.first

    expect(webhook_url.url).to eq('https://example.com/webhook')
  end

  it 'updates the webhook' do
    webhook_url = create(:webhook_url, account:, url: 'https://example.com/webhook')

    visit settings_webhooks_path

    fill_in 'Webhook URL', with: 'https://example.org/webhook'
    click_button 'Save'

    webhook_url.reload

    expect(webhook_url.url).to eq('https://example.org/webhook')
  end

  it 'deletes the webhook' do
    create(:webhook_url, account:)

    visit settings_webhooks_path

    fill_in 'Webhook URL', with: ''

    expect do
      click_button 'Save'
    end.to change(WebhookUrl, :count).by(-1)
  end

  it 'updates the webhook events' do
    webhook_url = create(:webhook_url, account:)

    visit settings_webhooks_path

    expect(webhook_url.events).not_to include('submission.created')

    check('submission.created')

    webhook_url.reload

    expect(webhook_url.events).to include('submission.created')
  end

  it 'adds a secret to the webhook' do
    webhook_url = create(:webhook_url, account:)

    visit settings_webhooks_path

    expect(webhook_url.secret).to eq({})

    click_link 'Add Secret'

    within '#modal' do
      fill_in 'Key', with: 'X-Signature'
      fill_in 'Value', with: 'secret-value'

      click_button 'Submit'

      webhook_url.reload

      expect(webhook_url.secret).to eq({ 'X-Signature' => 'secret-value' })
    end
  end

  it 'removes a secret from the webhook' do
    webhook_url = create(:webhook_url, account:, secret: { 'X-Signature' => 'secret-value' })

    visit settings_webhooks_path

    click_link 'Edit Secret'

    within '#modal' do
      fill_in 'Key', with: ''
      fill_in 'Value', with: ''

      click_button 'Submit'

      webhook_url.reload

      expect(webhook_url.secret).to eq({})
    end
  end
end
