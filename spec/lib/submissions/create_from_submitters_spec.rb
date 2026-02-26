# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Submissions::CreateFromSubmitters do
  let(:account) { create(:account) }
  let(:user) { create(:user, account:) }
  let(:template) { create(:template, account:, author: user, submitter_count: 2) }

  let(:submitter_attrs) do
    template.submitters.map do |s|
      { 'uuid' => s['uuid'], 'email' => Faker::Internet.email }.with_indifferent_access
    end
  end

  def call(template:, submitters_order:)
    described_class.call(
      template:,
      user:,
      submissions_attrs: [{ 'submitters' => submitter_attrs }.with_indifferent_access],
      source: :api,
      submitters_order:
    )
  end

  describe 'is_order_sent for employee_then_manager' do
    it 'sets sent_at only on the first submitter (Employee)' do
      submissions = call(template:, submitters_order: 'employee_then_manager')
      submitters = submissions.first.submitters.sort_by { |s| template.submitters.index { |ts| ts['uuid'] == s.uuid } }

      expect(submitters[0].sent_at).not_to be_nil
      expect(submitters[1].sent_at).to be_nil
    end
  end

  describe 'is_order_sent for manager_then_employee' do
    it 'sets sent_at only on the second submitter (Manager)' do
      submissions = call(template:, submitters_order: 'manager_then_employee')
      submitters = submissions.first.submitters.sort_by { |s| template.submitters.index { |ts| ts['uuid'] == s.uuid } }

      expect(submitters[0].sent_at).to be_nil
      expect(submitters[1].sent_at).not_to be_nil
    end
  end

  describe 'is_order_sent for simultaneous' do
    it 'sets sent_at on all submitters' do
      submissions = call(template:, submitters_order: 'simultaneous')

      expect(submissions.first.submitters).to all(have_attributes(sent_at: be_present))
    end
  end

  describe 'single_sided skipping' do
    before do
      manager_uuid = template.submitters[1]['uuid']
      template.update_column(:fields, template.fields.reject { |f| f['submitter_uuid'] == manager_uuid })
    end

    it 'skips submitters without fields' do
      submissions = call(template:, submitters_order: 'single_sided')
      submitter_uuids = submissions.first.submitters.map(&:uuid)

      expect(submitter_uuids).to include(template.submitters[0]['uuid'])
      expect(submitter_uuids).not_to include(template.submitters[1]['uuid'])
    end
  end
end
