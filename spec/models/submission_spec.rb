# frozen_string_literal: true

RSpec.describe Submission do
  let(:account) { create(:account) }
  let(:user) { create(:user, account:) }
  let(:template) { create(:template, account:, author: user) }
  let(:submission) { create(:submission, template:, created_by_user: user) }

  describe '#template_signing_order' do
    it 'returns the submitters_order from template preferences' do
      template.update!(preferences: { 'submitters_order' => 'employee_then_manager' })
      expect(submission.template_signing_order).to eq('employee_then_manager')
    end

    it 'returns nil when template has no submitters_order preference' do
      template.update_column(:preferences, {})
      expect(submission.reload.template_signing_order).to be_nil
    end

    it 'returns nil when submission has no template' do
      submission.update!(template: nil)
      expect(submission.template_signing_order).to be_nil
    end
  end

  describe '#signing_order_enforced?' do
    it 'returns true for employee_then_manager' do
      template.update!(preferences: { 'submitters_order' => 'employee_then_manager' })
      expect(submission.signing_order_enforced?).to be true
    end

    it 'returns true for manager_then_employee' do
      template.update!(preferences: { 'submitters_order' => 'manager_then_employee' })
      expect(submission.signing_order_enforced?).to be true
    end

    it 'returns false for simultaneous' do
      template.update!(preferences: { 'submitters_order' => 'simultaneous' })
      expect(submission.signing_order_enforced?).to be false
    end

    it 'returns false for single_sided' do
      template.update!(preferences: { 'submitters_order' => 'single_sided' })
      expect(submission.signing_order_enforced?).to be false
    end
  end
end
