# frozen_string_literal: true

require 'rails_helper'

class Rollbar
  def self.error(message); end
end

RSpec.describe ExportTemplateService do
  let(:export_location) { create(:export_location, :default) }
  let(:data) { { template: { name: 'Test Template' } } }
  let(:service) { described_class.new(data) }
  let(:faraday_connection) { instance_double(Faraday::Connection) }
  let(:faraday_response) { instance_double(Faraday::Response) }

  before do
    allow(ExportLocation).to receive(:default_location).and_return(export_location)
    allow(Faraday).to receive(:new).and_return(faraday_connection)
  end

  describe '#call' do
    let(:request_double) { instance_double(Net::HTTPGenericRequest, body: nil) }

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
        allow(faraday_connection).to receive(:post).with(export_location.templates_endpoint)
        service.call
        expect(faraday_connection).to have_received(:post).with(export_location.templates_endpoint)
      end

      it 'logs success message' do
        allow(Rails.logger).to receive(:info)
        service.call
        expect(Rails.logger).to have_received(:info)
          .with("Successfully exported template Test Template to #{export_location.name}")
      end
    end

    context 'when API request fails' do
      before do
        allow(faraday_response).to receive_messages(success?: false, status: 422)
      end

      it 'returns false and sets error message' do
        expect(service.call).to be false
        expect(service.error_message).to eq('Failed to export template to third party')
      end

      it 'logs error message' do
        allow(Rails.logger).to receive(:error)
        service.call
        expect(Rails.logger).to have_received(:error).with('Failed to export template to third party: 422')
      end

      it 'reports to Rollbar if available' do
        allow(Rollbar).to receive(:error)
        service.call
        expect(Rollbar).to have_received(:error).with("#{export_location.name} template export API error: 422")
      end
    end

    context 'when API response is nil' do
      before do
        allow(faraday_connection).to receive(:post).and_return(nil)
      end

      it 'returns false and sets error message' do
        expect(service.call).to be false
        expect(service.error_message).to eq('Failed to export template to third party')
      end
    end

    context 'when Faraday error occurs' do
      before do
        allow(faraday_connection).to receive(:post).and_raise(Faraday::ConnectionFailed.new('Connection failed'))
      end

      it 'returns false and sets network error message' do
        expect(service.call).to be false
        expect(service.error_message).to eq('Network error occurred during template export: Connection failed')
      end

      it 'logs the error' do
        allow(Rails.logger).to receive(:error)
        service.call
        expect(Rails.logger).to have_received(:error).with('Failed to export template Faraday: Connection failed')
      end

      it 'reports to Rollbar if available' do
        allow(Rollbar).to receive(:error)
        service.call
        expect(Rollbar).to have_received(:error).with('Failed to export template: Connection failed')
      end
    end

    context 'when other standard error occurs' do
      before do
        allow(ExportLocation).to receive(:default_location).and_raise(StandardError.new('Database error'))
      end

      it 'returns false and sets generic error message' do
        expect(service.call).to be false
        expect(service.error_message).to eq('An unexpected error occurred during template export: Database error')
      end

      it 'logs the error' do
        allow(Rails.logger).to receive(:error)
        service.call
        expect(Rails.logger).to have_received(:error).with('Failed to export template: Database error')
      end

      it 'reports to Rollbar if available' do
        allow(Rollbar).to receive(:error)
        error = StandardError.new('Database error')
        allow(ExportLocation).to receive(:default_location).and_raise(error)
        service.call
        expect(Rollbar).to have_received(:error).with(error)
      end
    end
  end

  describe 'data handling' do
    let(:request_double) { instance_double(Net::HTTPGenericRequest, body: nil) }

    before do
      allow(request_double).to receive(:body=)
      allow(faraday_connection).to receive(:post).and_yield(request_double).and_return(faraday_response)
      allow(faraday_response).to receive(:success?).and_return(true)
    end

    it 'sends the data in the request body' do
      allow(request_double).to receive(:body=)
      service.call
      expect(request_double).to have_received(:body=) do |body|
        expect(JSON.parse(body)).to eq(data.deep_stringify_keys)
      end
    end

    context 'when extra_params are provided' do
      let(:extra_params) { { 'api_key' => 'test_key', 'version' => '1.0' } }

      before do
        allow(export_location).to receive(:extra_params).and_return(extra_params)
      end

      it 'merges extra_params into the data' do
        allow(request_double).to receive(:body=)
        service.call
        expect(request_double).to have_received(:body=) do |body|
          parsed_body = JSON.parse(body)
          expect(parsed_body).to include('api_key' => 'test_key', 'version' => '1.0')
        end
      end
    end
  end
end
