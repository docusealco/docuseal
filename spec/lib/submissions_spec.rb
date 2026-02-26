# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Submissions do
  describe '.send_signature_requests' do
    let(:account) { create(:account) }
    let(:user) { create(:user, account:) }
    let(:template) { create(:template, account:, author: user, submitter_count: 2) }
    let(:submission) { create(:submission, template:, created_by_user: user) }

    let(:employee_uuid) { template.submitters[0]['uuid'] }
    let(:manager_uuid) { template.submitters[1]['uuid'] }

    let!(:employee) { create(:submitter, submission:, uuid: employee_uuid) }
    let!(:manager) { create(:submitter, submission:, uuid: manager_uuid) }

    before do
      allow(Submitters).to receive(:send_signature_requests)
    end

    def update_order(order)
      template.update_column(:preferences, { 'submitters_order' => order })
      submission.reload
    end

    context 'with employee_then_manager order' do
      before { update_order('employee_then_manager') }

      it 'sends signature request only to the employee first' do
        described_class.send_signature_requests([submission])

        expect(Submitters).to have_received(:send_signature_requests).with([employee], delay_seconds: nil)
      end
    end

    context 'with manager_then_employee order' do
      before { update_order('manager_then_employee') }

      it 'sends signature request only to the manager first' do
        described_class.send_signature_requests([submission])

        expect(Submitters).to have_received(:send_signature_requests).with([manager], delay_seconds: nil)
      end
    end

    context 'with simultaneous order' do
      before { update_order('simultaneous') }

      it 'sends signature requests to all submitters' do
        described_class.send_signature_requests([submission])

        expect(Submitters).to have_received(:send_signature_requests).with(contain_exactly(employee, manager),
                                                                           delay_seconds: nil)
      end
    end
  end
end
