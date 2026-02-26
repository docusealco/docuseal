# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Submitters do
  describe '.validate_submitter_order' do
    let(:account) { create(:account) }
    let(:user) { create(:user, account:) }
    let(:template) { create(:template, account:, author: user, submitter_count: 2) }
    let(:submission) { create(:submission, template:, created_by_user: user) }

    let(:employee_uuid) { template.submitters[0]['uuid'] }
    let(:manager_uuid) { template.submitters[1]['uuid'] }

    let!(:employee) { create(:submitter, submission:, uuid: employee_uuid) }
    let!(:manager) { create(:submitter, submission:, uuid: manager_uuid) }

    def update_order(order)
      template.update_column(:preferences, { 'submitters_order' => order })
      submission.reload
    end

    context 'with manager_then_employee order' do
      before { update_order('manager_then_employee') }

      it 'returns true for the manager (index 1)' do
        expect(described_class.validate_submitter_order(manager.reload)).to be true
      end

      it 'returns false for the employee when manager has not completed' do
        manager.update!(completed_at: nil)
        expect(described_class.validate_submitter_order(employee.reload)).to be false
      end

      it 'returns true for the employee when manager has completed' do
        manager.update!(completed_at: Time.current)
        expect(described_class.validate_submitter_order(employee.reload)).to be true
      end
    end

    context 'with employee_then_manager order' do
      before { update_order('employee_then_manager') }

      it 'returns true for the first submitter (Employee)' do
        expect(described_class.validate_submitter_order(employee.reload)).to be true
      end

      it 'returns false for the manager when employee has not completed' do
        employee.update!(completed_at: nil)
        expect(described_class.validate_submitter_order(manager.reload)).to be false
      end

      it 'returns true for the manager when employee has completed' do
        employee.update!(completed_at: Time.current)
        expect(described_class.validate_submitter_order(manager.reload)).to be true
      end
    end

    context 'with simultaneous order' do
      before { update_order('simultaneous') }

      it 'returns true for the first submitter' do
        expect(described_class.validate_submitter_order(employee.reload)).to be true
      end

      it 'returns true for the second submitter when the first has completed' do
        employee.update!(completed_at: Time.current)
        expect(described_class.validate_submitter_order(manager.reload)).to be true
      end

      it 'returns false for the second submitter when the first has not completed' do
        employee.update!(completed_at: nil)
        expect(described_class.validate_submitter_order(manager.reload)).to be false
      end
    end

    context 'with single_sided order' do
      before { update_order('single_sided') }

      it 'returns true for the first submitter' do
        expect(described_class.validate_submitter_order(employee.reload)).to be true
      end

      it 'returns true for the second submitter when the first has completed' do
        employee.update!(completed_at: Time.current)
        expect(described_class.validate_submitter_order(manager.reload)).to be true
      end

      it 'returns false for the second submitter when the first has not completed' do
        employee.update!(completed_at: nil)
        expect(described_class.validate_submitter_order(manager.reload)).to be false
      end
    end
  end
end
