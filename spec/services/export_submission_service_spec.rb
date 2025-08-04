# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExportSubmissionService do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:template) { create(:template, account: account, author: user) }
  let(:submission) do
    create(:submission, :with_submitters, template: template, account: account, created_by_user: user)
  end
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

    before do
      allow(request_double).to receive(:body=)
      allow(faraday_connection).to receive(:post)
        .with(export_location.submissions_endpoint)
        .and_yield(request_double)
        .and_return(faraday_response)
      allow(faraday_response).to receive(:success?).and_return(true)

      allow(Submitter).to receive(:after_update)

      submission.submitters.first.update!(name: 'John Doe', email: 'john@example.com', completed_at: Time.current)
      submission.submitters << create(
        :submitter,
        submission: submission,
        account: account,
        name: 'Jane Smith',
        email: 'jane@example.com',
        opened_at: Time.current,
        uuid: SecureRandom.uuid
      )
    end

    it 'builds correct payload structure with all required fields' do
      allow(request_double).to receive(:body=) do |body|
        parsed_body = JSON.parse(body)

        expect(parsed_body).to include(
          'external_submission_id' => submission.id,
          'template_name' => submission.template.name,
          'status' => 'in_progress'
        )
        expect(parsed_body).to have_key('created_at')
        expect(parsed_body).to have_key('updated_at')

        expect(parsed_body['submitter_data']).to be_an(Array)
        expect(parsed_body['submitter_data'].length).to eq(2)

        completed_submitter = parsed_body['submitter_data'].find { |s| s['status'] == 'completed' }
        expect(completed_submitter).to include(
          'name' => 'John Doe',
          'email' => 'john@example.com',
          'status' => 'completed'
        )
        expect(completed_submitter).to have_key('external_submitter_id')
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

  describe 'extra_params handling' do
    let(:request_double) { instance_double(Faraday::Request, body: nil) }

    before do
      allow(export_location).to receive(:extra_params).and_return({ 'api_key' => 'test_key', 'version' => '1.0' })
      allow(request_double).to receive(:body=)
      allow(faraday_connection).to receive(:post)
        .with(export_location.submissions_endpoint)
        .and_yield(request_double)
        .and_return(faraday_response)
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
