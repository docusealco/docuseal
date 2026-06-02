# frozen_string_literal: true

RSpec.describe 'Feature Toggles' do
  let(:account) { create(:account) }
  let(:author) { create(:user, account:) }

  describe 'allow decline toggle' do
    let(:template) { create(:template, account:, author:, only_field_types: %w[text]) }
    let(:submission) { create(:submission, template:) }
    let(:submitter) do
      create(:submitter, submission:, uuid: template.submitters.first['uuid'], account:)
    end

    it 'shows the decline button when enabled' do
      create(:account_config, account:, key: AccountConfig::ALLOW_TO_DECLINE_KEY, value: true)

      visit submit_form_path(slug: submitter.slug)

      expect(page).to have_selector('#decline_button')
    end

    it 'hides the decline button when disabled' do
      create(:account_config, account:, key: AccountConfig::ALLOW_TO_DECLINE_KEY, value: false)

      visit submit_form_path(slug: submitter.slug)

      expect(page).not_to have_selector('#decline_button')
    end
  end

  describe 'allow delegate toggle' do
    let(:template) { create(:template, account:, author:, only_field_types: %w[text]) }
    let(:submission) { create(:submission, template:) }
    let(:submitter) do
      create(:submitter, submission:, uuid: template.submitters.first['uuid'], account:)
    end

    it 'shows the delegate button when enabled' do
      create(:account_config, account:, key: AccountConfig::ALLOW_TO_DELEGATE_KEY, value: true)

      visit submit_form_path(slug: submitter.slug)

      expect(page).to have_selector('#delegate_button')
    end

    it 'hides the delegate button when disabled' do
      create(:account_config, account:, key: AccountConfig::ALLOW_TO_DELEGATE_KEY, value: false)

      visit submit_form_path(slug: submitter.slug)

      expect(page).not_to have_selector('#delegate_button')
    end
  end

  describe 'require signing reason toggle' do
    let(:template) { create(:template, account:, author:, only_field_types: %w[signature]) }
    let(:submission) { create(:submission, template:) }
    let(:submitter) do
      create(:submitter, submission:, uuid: template.submitters.first['uuid'], account:)
    end

    it 'shows the signing reason select when enabled' do
      create(:account_config, account:, key: AccountConfig::REQUIRE_SIGNING_REASON_KEY, value: true)

      visit submit_form_path(slug: submitter.slug)

      find('#expand_form_button').click

      expect(page).to have_css('select.base-input')
    end

    it 'hides the signing reason select when disabled' do
      create(:account_config, account:, key: AccountConfig::REQUIRE_SIGNING_REASON_KEY, value: false)

      visit submit_form_path(slug: submitter.slug)

      find('#expand_form_button').click

      expect(page).not_to have_css('select.base-input')
    end
  end

  describe 'enforce signing order toggle' do
    let(:template) do
      create(:template, submitter_count: 2, account:, author:, only_field_types: %w[text])
    end
    let(:submission) { create(:submission, template:, template_fields: template.fields) }
    let(:first_submitter) do
      create(:submitter, submission:, uuid: template.submitters[0]['uuid'], account:,
                         email: 'first@example.com')
    end
    let(:second_submitter) do
      create(:submitter, submission:, uuid: template.submitters[1]['uuid'], account:,
                         email: 'second@example.com')
    end

    pending 'blocks the second signer when enabled' do
      create(:account_config, account:, key: AccountConfig::ENFORCE_SIGNING_ORDER_KEY, value: true)

      visit submit_form_path(slug: second_submitter.slug)

      expect(page).to have_content('Awaiting completion by the other party')
    end

    it 'allows the second signer to proceed when disabled' do
      create(:account_config, account:, key: AccountConfig::ENFORCE_SIGNING_ORDER_KEY, value: false)

      visit submit_form_path(slug: second_submitter.slug)

      expect(page).to have_field('First Name')
    end
  end

  describe 'allow typed signature toggle' do
    let(:template) { create(:template, account:, author:, only_field_types: %w[signature]) }
    let(:submission) { create(:submission, template:) }
    let(:submitter) do
      create(:submitter, submission:, uuid: template.submitters.first['uuid'], account:)
    end

    it 'shows the Type button when enabled' do
      create(:account_config, account:, key: AccountConfig::ALLOW_TYPED_SIGNATURE, value: true)

      visit submit_form_path(slug: submitter.slug)

      find('#expand_form_button').click

      expect(page).to have_button('Type')
    end

    it 'hides the Type button when disabled' do
      create(:account_config, account:, key: AccountConfig::ALLOW_TYPED_SIGNATURE, value: false)

      visit submit_form_path(slug: submitter.slug)

      find('#expand_form_button').click

      expect(page).not_to have_button('Type')
    end
  end

  describe 'force MFA toggle', :multitenant do
    let(:other_account) { create(:account) }
    let(:other_user) { create(:user, account: other_account) }

    pending 'does not affect users who already have MFA configured' do
      create(:account_config, account: other_account, key: AccountConfig::FORCE_MFA, value: true)

      sign_in(other_user)

      visit root_path

      expect(page).to have_current_path(root_path)
    end
  end

  describe 'allow resubmit toggle' do
    let(:template) do
      create(:template, shared_link: true, account:, author:, only_field_types: %w[text])
    end

    it 'allows resubmission when enabled' do
      create(:account_config, account:, key: AccountConfig::ALLOW_TO_RESUBMIT, value: true)

      visit start_form_path(slug: template.slug)

      fill_in 'Email', with: 'test@example.com'
      click_button 'Start'

      fill_in 'First Name', with: 'First Try'
      find('#submit_form_button').click

      expect(page).to have_content('Form has been completed!')

      visit start_form_path(slug: template.slug)

      fill_in 'Email', with: 'test@example.com'
      click_button 'Start'

      expect(page).not_to have_content('already completed')
    end
  end
end
