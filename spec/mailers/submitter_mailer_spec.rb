# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubmitterMailer, type: :mailer do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, first_name: 'John', last_name: 'Doe') }
  let(:template) { create(:template, account: account, author: user) }
  let(:submission) { create(:submission, template: template, account: account, created_by_user: user) }
  let(:submitter) do
    create(
      :submitter,
      submission: submission,
      account: account,
      email: 'test@example.com',
      name: 'Jane Smith',
      uuid: template.submitters.first['uuid']
    )
  end

  describe '#changes_requested_email' do
    let(:reason) { 'Please fix the signature field' }
    let(:mail) { described_class.changes_requested_email(submitter, user, reason) }

    it 'sets the correct email attributes' do
      expect(mail.to).to eq(['test@example.com'])
      expect(mail.subject).to include('Changes requested')
      expect(mail.from).to be_present
    end

    it 'includes the reason in the email body' do
      expect(mail.body.encoded).to include(reason)
    end

    it 'includes the user name in the email body' do
      expect(mail.body.encoded).to include('John Doe')
    end

    it 'includes the submitter name in the greeting' do
      expect(mail.body.encoded).to include('Jane Smith')
    end

    it 'includes resubmit instructions' do
      expect(mail.body.encoded).to include('resubmit')
    end
  end
end
