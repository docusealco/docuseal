# frozen_string_literal: true

RSpec.describe 'Webhook Settings' do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }

  before do
    sign_in(user)
  end

  it 'shows webhook settings page with empty form when there are no webhooks' do
    visit settings_webhooks_path

    expect(page).to have_content('Webhook')
    expect(page).to have_content('Webhook URL')
    expect(page).to have_field('webhook_url[url]', type: 'url')
    expect(page).to have_button('Save')

    WebhookUrl::EVENTS.each do |event|
      expect(page).to have_field(event, type: 'checkbox')
    end
  end

  it 'shows list of webhooks when there are more than one' do
    webhook_urls = create_list(:webhook_url, 2, account:)

    visit settings_webhooks_path

    expect(page).to have_content('Webhooks')
    expect(page).to have_link('New Webhook')

    webhook_urls.each do |webhook_url|
      expect(page).to have_content(webhook_url.url)

      within("a[href='#{settings_webhook_path(webhook_url)}']") do
        webhook_url.events.each do |event|
          expect(page).to have_content(event)
        end
      end
    end
  end

  it 'shows webhook settings page with pre-filled form when there is one webhook' do
    webhook_url = create(:webhook_url, account:)

    visit settings_webhooks_path

    expect(page).to have_content('Webhook')
    expect(page).to have_field('webhook_url[url]', type: 'url', with: webhook_url.url)
    expect(page).to have_button('Save')
    expect(page).to have_button('Delete')
    expect(page).to have_link('Add Secret')

    WebhookUrl::EVENTS.each do |event|
      expect(page).to have_field(event, type: 'checkbox', checked: webhook_url.events.include?(event))
    end
  end

  it 'creates the webhook' do
    visit settings_webhooks_path

    fill_in 'webhook_url[url]', with: 'https://example.com/webhook'

    expect do
      click_button 'Save'
    end.to change(WebhookUrl, :count).by(1)

    webhook_url = account.webhook_urls.first

    expect(webhook_url.url).to eq('https://example.com/webhook')
    expect(page).to have_content('Webhook URL has been saved.')
    expect(page.current_path).to eq(settings_webhooks_path)
  end

  it 'updates the webhook' do
    webhook_url = create(:webhook_url, account:, url: 'https://example.com/webhook')

    visit settings_webhooks_path

    fill_in 'webhook_url[url]', with: 'https://example.org/webhook'
    click_button 'Save'

    webhook_url.reload

    expect(webhook_url.url).to eq('https://example.org/webhook')
    expect(page).to have_content('Webhook URL has been updated.')
    expect(page.current_path).to eq(settings_webhooks_path)
  end

  it 'deletes the webhook' do
    create(:webhook_url, account:)

    visit settings_webhooks_path

    expect do
      accept_confirm('Are you sure?') do
        click_button 'Delete'
      end
    end.to change(WebhookUrl, :count).by(-1)

    expect(page).to have_content('Webhook URL has been deleted.')
    expect(page.current_path).to eq(settings_webhooks_path)
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

    expect(page).to have_link('Edit Secret')
    expect(page).to have_content('Webhook Secret has been saved.')
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

    expect(page).to have_link('Add Secret')
    expect(page).to have_content('Webhook Secret has been saved.')
  end

  context 'when testing the webhook' do
    let!(:webhook_url) { create(:webhook_url, account:) }
    let!(:template) { create(:template, account:, author: user) }
    let!(:submission) { create(:submission, template:, created_by_user: user) }
    let!(:submitter) do
      create(:submitter, submission:, uuid: template.submitters.first['uuid'], completed_at: Time.current)
    end

    it 'sends the webhook request' do
      visit settings_webhooks_path

      expect do
        click_button 'Test Webhook'
      end.to change(SendFormCompletedWebhookRequestJob.jobs, :size).by(1)

      args = SendFormCompletedWebhookRequestJob.jobs.last['args'].first

      expect(args['webhook_url_id']).to eq(webhook_url.id)
      expect(args['submitter_id']).to eq(submitter.id)
      expect(page).to have_content('Webhook request has been sent.')
    end
  end
end
