# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Submitter do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:template) { create(:template, account: account, author: user) }
  let(:submission) do
    create(:submission, :with_submitters, template: template, account: account, created_by_user: user)
  end
  let(:submitter) { submission.submitters.first }

  describe '#status' do
    context 'when submitter is awaiting' do
      it 'returns awaiting' do
        expect(submitter.status).to eq('awaiting')
      end
    end

    context 'when submitter is sent' do
      before { submitter.update!(sent_at: Time.current) }

      it 'returns sent' do
        expect(submitter.status).to eq('sent')
      end
    end

    context 'when submitter is opened' do
      before do
        submitter.update!(sent_at: Time.current, opened_at: Time.current)
      end

      it 'returns opened' do
        expect(submitter.status).to eq('opened')
      end
    end

    context 'when submitter is completed' do
      before do
        submitter.update!(
          sent_at: Time.current,
          opened_at: Time.current,
          completed_at: Time.current
        )
      end

      it 'returns completed' do
        expect(submitter.status).to eq('completed')
      end
    end

    context 'when submitter is declined' do
      before { submitter.update!(declined_at: Time.current) }

      it 'returns declined' do
        expect(submitter.status).to eq('declined')
      end
    end

    context 'when submitter is declined but also completed' do
      before do
        submitter.update!(
          completed_at: Time.current,
          declined_at: Time.current
        )
      end

      it 'returns declined (declined takes precedence)' do
        expect(submitter.status).to eq('declined')
      end
    end

    context 'when submitter has changes requested' do
      before { submitter.update!(changes_requested_at: Time.current) }

      it 'returns changes_requested' do
        expect(submitter.status).to eq('changes_requested')
      end
    end

    context 'when submitter has changes requested but is also completed' do
      before do
        submitter.update!(
          completed_at: Time.current,
          changes_requested_at: Time.current
        )
      end

      it 'returns changes_requested (changes_requested takes precedence over completed)' do
        expect(submitter.status).to eq('changes_requested')
      end
    end
  end

  describe '#export_submission_on_status_change' do
    let(:export_location) { create(:export_location, :with_submissions_endpoint) }
    let(:export_service) { instance_double(ExportSubmissionService) }

    before do
      allow(ExportLocation).to receive(:default_location).and_return(export_location)
      allow(ExportSubmissionService).to receive(:new).with(submission).and_return(export_service)
      allow(export_service).to receive(:call).and_return(true)
    end

    context 'when status-related field changes' do
      it 'calls ExportSubmissionService when completed_at changes' do
        submitter.update!(completed_at: Time.current)
        expect(ExportSubmissionService).to have_received(:new).with(submission)
        expect(export_service).to have_received(:call)
      end

      it 'calls ExportSubmissionService when declined_at changes' do
        submitter.update!(declined_at: Time.current)
        expect(ExportSubmissionService).to have_received(:new).with(submission)
        expect(export_service).to have_received(:call)
      end

      it 'calls ExportSubmissionService when opened_at changes' do
        submitter.update!(opened_at: Time.current)
        expect(ExportSubmissionService).to have_received(:new).with(submission)
        expect(export_service).to have_received(:call)
      end

      it 'calls ExportSubmissionService when sent_at changes' do
        submitter.update!(sent_at: Time.current)
        expect(ExportSubmissionService).to have_received(:new).with(submission)
        expect(export_service).to have_received(:call)
      end
    end

    context 'when non-status field changes' do
      it 'does not call ExportSubmissionService when email changes' do
        submitter.update!(email: 'new@example.com')
        expect(ExportSubmissionService).not_to have_received(:new)
        expect(export_service).not_to have_received(:call)
      end

      it 'does not call ExportSubmissionService when name changes' do
        submitter.update!(name: 'New Name')
        expect(ExportSubmissionService).not_to have_received(:new)
        expect(export_service).not_to have_received(:call)
      end
    end

    context 'when export service raises an error' do
      before do
        allow(export_service).to receive(:call).and_raise(StandardError.new('Export failed'))
        allow(Rails.logger).to receive(:error)
      end

      it 'logs the error and does not re-raise' do
        expect { submitter.update!(completed_at: Time.current) }.not_to raise_error
        expect(Rails.logger).to have_received(:error).with(
          'Failed to export submission on status change: Export failed'
        )
      end
    end

    context 'when ExportLocation.default_location returns nil' do
      before do
        allow(ExportLocation).to receive(:default_location).and_return(nil)
        allow(export_service).to receive(:call).and_return(false)
      end

      it 'calls ExportSubmissionService but service handles nil export location' do
        submitter.update!(completed_at: Time.current)
        expect(ExportSubmissionService).to have_received(:new).with(submission)
        expect(export_service).to have_received(:call)
      end
    end

    context 'when export location has no submissions_endpoint' do
      before do
        allow(export_location).to receive(:submissions_endpoint).and_return(nil)
        allow(export_service).to receive(:call).and_return(false)
      end

      it 'calls ExportSubmissionService but service handles missing endpoint' do
        submitter.update!(completed_at: Time.current)
        expect(ExportSubmissionService).to have_received(:new).with(submission)
        expect(export_service).to have_received(:call)
      end
    end
  end
end
