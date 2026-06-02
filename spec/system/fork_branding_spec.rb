# frozen_string_literal: true

RSpec.describe 'Fork Branding' do
  let(:account) { create(:account) }
  let(:user) { create(:user, account:) }

  before do
    sign_in(user)
  end

  it 'displays the default product name in the shared title' do
    visit settings_personalization_path

    expect(page).to have_content(Wabosign::PRODUCT_NAME)
  end

  it 'displays the brand name in the shared title after setting one' do
    create(:account_config, account:, key: AccountConfig::BRAND_NAME_KEY, value: 'Acme Sign')

    visit settings_personalization_path

    expect(page).to have_content('Acme Sign')
  expect(page).to have_link('Acme Sign', href: root_path)
  end

  it 'shows the brand name form on the personalization settings page' do
    visit settings_personalization_path

    expect(page).to have_field('brand_name', placeholder: 'e.g. Acme Sign')
    expect(page).to have_button('Save')
  end

  it 'saves a brand name via the form' do
    visit settings_personalization_path

    fill_in 'brand_name', with: 'My Brand'
    click_button 'Save'

    expect(page).to have_content(I18n.t('settings_have_been_saved'))
    expect(account.reload.brand_name).to eq('My Brand')
  end

  it 'clears the brand name via the form' do
    create(:account_config, account:, key: AccountConfig::BRAND_NAME_KEY, value: 'Acme Sign')

    visit settings_personalization_path

    fill_in 'brand_name', with: ''
    click_button 'Save'

    expect(page).to have_content(I18n.t('settings_have_been_saved'))
    expect(account.reload.brand_name).to be_nil
  end

  it 'shows the upstream attribution link on the personalization settings page' do
    visit settings_personalization_path

    expect(page).to have_link(Wabosign::UPSTREAM_NAME, href: Wabosign::UPSTREAM_URL)
  end

  it 'renders the product name on the start form for a shared-link template' do
    template = create(:template, shared_link: true, account:, author: user,
                                 except_field_types: %w[phone payment stamp])

    visit start_form_path(slug: template.slug)

    expect(page).to have_content(Wabosign::PRODUCT_NAME)
  end

  it 'renders the product name on the submit form for a direct submission' do
    template = create(:template, account:, author: user, only_field_types: %w[text])
    submission = create(:submission, template:)
    submitter = create(:submitter, submission:, uuid: template.submitters.first['uuid'], account:)

    visit submit_form_path(slug: submitter.slug)

    expect(page).to have_content(Wabosign::PRODUCT_NAME)
  end

  it 'renders the upstream powered-by attribution on the start form' do
    template = create(:template, shared_link: true, account:, author: user,
                                 except_field_types: %w[phone payment stamp])

    visit start_form_path(slug: template.slug)

    expect(page).to have_content(I18n.t('powered_by'))
  end
end
