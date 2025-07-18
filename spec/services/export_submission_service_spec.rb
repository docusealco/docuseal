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
      let(:request_double) { double('request', body: nil) }

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
          expect(faraday_connection).to receive(:post).with(export_location.submissions_endpoint)
          service.call
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
        expect(Rails.logger).to receive(:error).with('Failed to export submission Faraday: Connection failed')
        service.call
      end

      it 'reports to Rollbar if available' do
        stub_const('Rollbar', double)
        expect(Rollbar).to receive(:error).with('Failed to export submission: Connection failed')
        service.call
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
        expect(Rails.logger).to receive(:error).with('Failed to export submission: Database error')
        service.call
      end

      it 'reports to Rollbar if available' do
        stub_const('Rollbar', double)
        error = StandardError.new('Database error')
        allow(ExportLocation).to receive(:default_location).and_raise(error)
        expect(Rollbar).to receive(:error).with(error)
        service.call
      end
    end
  end

  describe 'payload building' do
    let(:request_double) { double('request', body: nil) }

    before do
      allow(request_double).to receive(:body=)
      allow(faraday_connection).to receive(:post).and_yield(request_double).and_return(faraday_response)
      allow(faraday_response).to receive(:success?).and_return(true)
    end

    it 'includes submission_id in payload' do
      expect(request_double).to receive(:body=) do |body|
        expect(JSON.parse(body)).to include('submission_id' => submission.id)
      end
      service.call
    end

    it 'includes template_name in payload' do
      expect(request_double).to receive(:body=) do |body|
        expect(JSON.parse(body)).to include('template_name' => submission.template.name)
      end
      service.call
    end

    it 'includes recent events in payload' do
      expect(request_double).to receive(:body=) do |body|
        parsed_body = JSON.parse(body)
        expect(parsed_body).to have_key('events')
      end
      service.call
    end

    context 'when template is nil' do
      before do
        allow(submission).to receive(:template).and_return(nil)
      end

      it 'includes nil template_name in payload' do
        expect(request_double).to receive(:body=) do |body|
          expect(JSON.parse(body)).to include('template_name' => nil)
        end
        service.call
      end
    end
  end

  describe 'extra_params handling' do
    let(:extra_params) { { 'api_key' => 'test_key', 'version' => '1.0' } }
    let(:request_double) { double('request', body: nil) }

    before do
      allow(export_location).to receive(:extra_params).and_return(extra_params)
      allow(request_double).to receive(:body=)
      allow(faraday_connection).to receive(:post).and_yield(request_double).and_return(faraday_response)
      allow(faraday_response).to receive(:success?).and_return(true)
    end

    it 'merges extra_params into the payload' do
      expect(request_double).to receive(:body=) do |body|
        parsed_body = JSON.parse(body)
        expect(parsed_body).to include('api_key' => 'test_key', 'version' => '1.0')
      end
      service.call
    end
  end
end
