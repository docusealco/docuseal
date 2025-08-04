# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExportSubmissionService do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:template) { create(:template, account: account, author: user) }
  let(:submission) { create(:submission, template: template, account: account) }
  let(:export_location) { create(:export_location, :with_submissions_endpoint) }
  let(:service) { described_class.new(submission) }
  let(:faraday_connection) { instance_double(Faraday::Connection) }
  let(:faraday_response) { instance_double(Faraday::Response) }

  before do
    allow(ExportLocation).to receive(:default_location).and_return(export_location)
    allow(Faraday).to receive(:new).and_return(faraday_connection)
  end

  describe '#call' do
    context 'when export location is not configured' do
      before do
        allow(ExportLocation).to receive(:default_location).and_return(nil)
      end

      it 'returns false and sets error message' do
        expect(service.call).to be false
        expect(service.error_message).to eq('Export failed: Submission export endpoint is not configured.')
      end
    end

    context 'when export location has no submissions endpoint' do
      before do
        allow(export_location).to receive(:submissions_endpoint).and_return(nil)
      end

      it 'returns false and sets error message' do
        expect(service.call).to be false
        expect(service.error_message).to eq('Export failed: Submission export endpoint is not configured.')
      end
    end

    context 'when export location is properly configured' do
      let(:request_double) { instance_double(Faraday::Request, body: nil) }

      before do
        allow(request_double).to receive(:body=)
        allow(faraday_connection).to receive(:post).and_yield(request_double).and_return(faraday_response)
      end

      context 'when API request succeeds' do
        before do
          allow(faraday_response).to receive(:success?).and_return(true)
        end

        it 'returns true' do
          expect(service.call).to be true
        end

        it 'makes API call with correct endpoint' do
          allow(faraday_connection).to receive(:post).with(export_location.submissions_endpoint)
          service.call
          expect(faraday_connection).to have_received(:post).with(export_location.submissions_endpoint)
        end
      end

      context 'when API request fails' do
        before do
          allow(faraday_response).to receive(:success?).and_return(false)
        end

        it 'returns false and sets error message' do
          expect(service.call).to be false
          expect(service.error_message).to eq("Failed to export submission ##{submission.id} events.")
        end
      end

      context 'when API response is nil' do
        before do
          allow(faraday_connection).to receive(:post).and_return(nil)
        end

        it 'returns false and sets error message' do
          expect(service.call).to be false
          expect(service.error_message).to eq("Failed to export submission ##{submission.id} events.")
        end
      end
    end

    context 'when Faraday error occurs' do
      before do
        allow(faraday_connection).to receive(:post).and_raise(Faraday::ConnectionFailed.new('Connection failed'))
      end

      it 'returns false and sets network error message' do
        expect(service.call).to be false
        expect(service.error_message).to eq('Network error occurred during export: Connection failed')
      end

      it 'logs the error' do
        allow(Rails.logger).to receive(:error)
        service.call
        expect(Rails.logger).to have_received(:error)
      end

      it 'reports to Rollbar if available' do
        stub_const('Rollbar', double)
        allow(Rollbar).to receive(:error)
        service.call
        expect(Rollbar).to have_received(:error)
      end
    end

    context 'when other standard error occurs' do
      before do
        allow(ExportLocation).to receive(:default_location).and_raise(StandardError.new('Database error'))
      end

      it 'returns false and sets generic error message' do
        expect(service.call).to be false
        expect(service.error_message).to eq('An unexpected error occurred during export: Database error')
      end

      it 'logs the error' do
        allow(Rails.logger).to receive(:error)
        service.call
        expect(Rails.logger).to have_received(:error)
      end

      it 'reports to Rollbar if available' do
        stub_const('Rollbar', double)
        error = StandardError.new('Database error')
        allow(ExportLocation).to receive(:default_location).and_raise(error)
        allow(Rollbar).to receive(:error)
        service.call
        expect(Rollbar).to have_received(:error).with(error)
      end
    end
  end

  describe 'payload building' do
    let(:request_double) { instance_double(Faraday::Request, body: nil) }
    let(:submitter1) { create(:submitter, submission: submission, account: account, name: 'John Doe', email: 'john@example.com', completed_at: Time.current, uuid: SecureRandom.uuid) }
    let(:submitter2) { create(:submitter, submission: submission, account: account, name: 'Jane Smith', email: 'jane@example.com', opened_at: Time.current, uuid: SecureRandom.uuid) }

    before do
      submission.submitters << [submitter1, submitter2]
      allow(request_double).to receive(:body=)
      allow(faraday_connection).to receive(:post).and_yield(request_double).and_return(faraday_response)
      allow(faraday_response).to receive(:success?).and_return(true)
    end

    it 'includes external_submission_id in payload' do
      allow(request_double).to receive(:body=) do |body|
        expect(JSON.parse(body)).to include('external_submission_id' => submission.id)
      end
      service.call
    end

    it 'includes template_name in payload' do
      allow(request_double).to receive(:body=) do |body|
        expect(JSON.parse(body)).to include('template_name' => submission.template.name)
      end
      service.call
    end

    it 'includes submission status in payload' do
      allow(request_double).to receive(:body=) do |body|
        expect(JSON.parse(body)).to include('status' => 'in_progress')
      end
      service.call
    end

    it 'includes submitter_data array in payload' do
      allow(request_double).to receive(:body=) do |body|
        parsed_body = JSON.parse(body)
        expect(parsed_body).to have_key('submitter_data')
        expect(parsed_body['submitter_data']).to be_an(Array)
        expect(parsed_body['submitter_data'].length).to eq(2)
      end
      service.call
    end

    it 'includes correct submitter data in payload' do
      allow(request_double).to receive(:body=) do |body|
        parsed_body = JSON.parse(body)
        submitter_data = parsed_body['submitter_data']

        first_submitter = submitter_data.find { |s| s['email'] == 'john@example.com' }
        expect(first_submitter).to include(
          'external_submitter_id' => submitter1.slug,
          'name' => 'John Doe',
          'email' => 'john@example.com',
          'status' => 'completed'
        )

        second_submitter = submitter_data.find { |s| s['email'] == 'jane@example.com' }
        expect(second_submitter).to include(
          'external_submitter_id' => submitter2.slug,
          'name' => 'Jane Smith',
          'email' => 'jane@example.com',
          'status' => 'opened'
        )
      end
      service.call
    end

    it 'includes created_at and updated_at in payload' do
      allow(request_double).to receive(:body=) do |body|
        parsed_body = JSON.parse(body)
        expect(parsed_body).to have_key('created_at')
        expect(parsed_body).to have_key('updated_at')
      end
      service.call
    end

    context 'when template is nil' do
      before do
        allow(submission).to receive(:template).and_return(nil)
      end

      it 'includes nil template_name in payload' do
        allow(request_double).to receive(:body=) do |body|
          expect(JSON.parse(body)).to include('template_name' => nil)
        end
        service.call
      end
    end
  end

  describe '#submission_status' do
    let(:service) { described_class.new(submission) }

    context 'with multiple submitters' do
      let(:submitter1) { create(:submitter, submission: submission, account: account, uuid: SecureRandom.uuid) }
      let(:submitter2) { create(:submitter, submission: submission, account: account, uuid: SecureRandom.uuid) }

      before do
        submission.submitters << [submitter1, submitter2]
      end

      it 'returns declined when any submitter is declined' do
        submitter1.declined_at = Time.current
        submitter2.completed_at = Time.current
        expect(service.send(:submission_status)).to eq('declined')
      end

      it 'returns completed when all submitters are completed' do
        submitter1.completed_at = Time.current
        submitter2.completed_at = Time.current
        expect(service.send(:submission_status)).to eq('completed')
      end

      it 'returns in_progress when any submitter is opened but not all completed' do
        submitter1.opened_at = Time.current
        submitter2.sent_at = Time.current
        expect(service.send(:submission_status)).to eq('in_progress')
      end

      it 'returns sent when any submitter is sent but none opened' do
        submitter1.sent_at = Time.current
        expect(service.send(:submission_status)).to eq('sent')
      end

      it 'returns pending when no submitters have been sent' do
        expect(service.send(:submission_status)).to eq('pending')
      end
    end

    context 'with single submitter' do
      let(:submitter) { create(:submitter, submission: submission, account: account, uuid: SecureRandom.uuid) }

      before do
        submission.submitters << submitter
      end

      it 'returns the submitter status when single submitter' do
        submitter.opened_at = Time.current
        expect(service.send(:submission_status)).to eq('in_progress')
      end
    end
  end

  describe 'extra_params handling' do
    let(:request_double) { instance_double(Faraday::Request, body: nil) }

    before do
      allow(export_location).to receive(:extra_params).and_return({ 'api_key' => 'test_key', 'version' => '1.0' })
      allow(request_double).to receive(:body=)
      allow(faraday_connection).to receive(:post).and_yield(request_double).and_return(faraday_response)
      allow(faraday_response).to receive(:success?).and_return(true)
    end

    it 'merges extra_params into the payload' do
      allow(request_double).to receive(:body=) do |body|
        parsed_body = JSON.parse(body)
        expect(parsed_body).to include('api_key' => 'test_key', 'version' => '1.0')
      end
      service.call
    end
  end
end
