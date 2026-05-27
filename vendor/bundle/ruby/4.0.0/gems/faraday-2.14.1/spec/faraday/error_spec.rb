# frozen_string_literal: true

RSpec.describe Faraday::Error do
  describe '.initialize' do
    subject { described_class.new(exception, response) }
    let(:response) { nil }

    context 'with exception only' do
      let(:exception) { RuntimeError.new('test') }

      it { expect(subject.wrapped_exception).to eq(exception) }
      it { expect(subject.response).to be_nil }
      it { expect(subject.message).to eq(exception.message) }
      it { expect(subject.backtrace).to eq(exception.backtrace) }
      it { expect(subject.inspect).to eq('#<Faraday::Error wrapped=#<RuntimeError: test>>') }
      it { expect(subject.response_status).to be_nil }
      it { expect(subject.response_headers).to be_nil }
      it { expect(subject.response_body).to be_nil }
    end

    context 'with response hash' do
      let(:exception) { { status: 400 } }

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to eq(exception) }
      it { expect(subject.message).to eq('the server responded with status 400 - method and url are not available due to include_request: false on Faraday::Response::RaiseError middleware') }
      if RUBY_VERSION >= '3.4'
        it { expect(subject.inspect).to eq('#<Faraday::Error response={status: 400}>') }
      else
        it { expect(subject.inspect).to eq('#<Faraday::Error response={:status=>400}>') }
      end
      it { expect(subject.response_status).to eq(400) }
      it { expect(subject.response_headers).to be_nil }
      it { expect(subject.response_body).to be_nil }
    end

    context 'with string' do
      let(:exception) { 'custom message' }

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to be_nil }
      it { expect(subject.message).to eq('custom message') }
      it { expect(subject.inspect).to eq('#<Faraday::Error #<Faraday::Error: custom message>>') }
      it { expect(subject.response_status).to be_nil }
      it { expect(subject.response_headers).to be_nil }
      it { expect(subject.response_body).to be_nil }
    end

    context 'with anything else #to_s' do
      let(:exception) { %w[error1 error2] }

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to be_nil }
      it { expect(subject.message).to eq('["error1", "error2"]') }
      it { expect(subject.inspect).to eq('#<Faraday::Error #<Faraday::Error: ["error1", "error2"]>>') }
      it { expect(subject.response_status).to be_nil }
      it { expect(subject.response_headers).to be_nil }
      it { expect(subject.response_body).to be_nil }
    end

    context 'with exception string and response hash' do
      let(:exception) { 'custom message' }
      let(:response) { { status: 400 } }

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to eq(response) }
      it { expect(subject.message).to eq('custom message') }
      if RUBY_VERSION >= '3.4'
        it { expect(subject.inspect).to eq('#<Faraday::Error response={status: 400}>') }
      else
        it { expect(subject.inspect).to eq('#<Faraday::Error response={:status=>400}>') }
      end
      it { expect(subject.response_status).to eq(400) }
      it { expect(subject.response_headers).to be_nil }
      it { expect(subject.response_body).to be_nil }
    end

    context 'with exception and response object' do
      let(:exception) { RuntimeError.new('test') }
      let(:body) { { test: 'test' } }
      let(:headers) { { 'Content-Type' => 'application/json' } }
      let(:response) { Faraday::Response.new(status: 400, response_headers: headers, response_body: body) }

      it { expect(subject.wrapped_exception).to eq(exception) }
      it { expect(subject.response).to eq(response) }
      it { expect(subject.message).to eq(exception.message) }
      it { expect(subject.backtrace).to eq(exception.backtrace) }
      it { expect(subject.response_status).to eq(400) }
      it { expect(subject.response_headers).to eq(headers) }
      it { expect(subject.response_body).to eq(body) }
    end

    context 'with hash missing status key' do
      let(:exception) { { body: 'error body' } }

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to eq(exception) }
      it { expect(subject.message).to eq('the server responded with status  - method and url are not available due to include_request: false on Faraday::Response::RaiseError middleware') }
    end

    context 'with hash with status but missing request data' do
      let(:exception) { { status: 404, body: 'not found' } } # missing request key

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to eq(exception) }
      it { expect(subject.message).to eq('the server responded with status 404 - method and url are not available due to include_request: false on Faraday::Response::RaiseError middleware') }
    end

    context 'with hash with status and request but missing method in request' do
      let(:exception) { { status: 404, body: 'not found', request: { url: 'http://example.com/test' } } } # missing method

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to eq(exception) }
      it { expect(subject.message).to eq('the server responded with status 404 for  http://example.com/test') }
    end

    context 'with hash with status and request but missing url in request' do
      let(:exception) { { status: 404, body: 'not found', request: { method: :get } } } # missing url

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to eq(exception) }
      it { expect(subject.message).to eq('the server responded with status 404 for GET ') }
    end

    context 'with properly formed Faraday::Env' do
      # This represents the normal case - a well-formed Faraday::Env object
      # with all the standard properties populated as they would be during
      # a typical HTTP request/response cycle
      let(:exception) { Faraday::Env.new }

      before do
        exception.status = 500
        exception.method = :post
        exception.url = URI('https://api.example.com/users')
        exception.request = Faraday::RequestOptions.new
        exception.response_headers = { 'content-type' => 'application/json' }
        exception.response_body = '{"error": "Internal server error"}'
        exception.request_headers = { 'authorization' => 'Bearer token123' }
        exception.request_body = '{"name": "John"}'
      end

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to eq(exception) }
      it { expect(subject.message).to eq('the server responded with status 500 for POST https://api.example.com/users') }
    end

    context 'with Faraday::Env missing status key' do
      let(:exception) { Faraday::Env.new }

      before do
        exception[:body] = 'error body'
        # Intentionally not setting status
      end

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to eq(exception) }
      it { expect(subject.message).to eq('the server responded with status  for  ') }
    end

    context 'with Faraday::Env with direct method and url properties' do
      let(:exception) { Faraday::Env.new }

      before do
        exception.status = 404
        exception.method = :get
        exception.url = URI('http://example.com/test')
        exception[:body] = 'not found'
      end

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to eq(exception) }
      it { expect(subject.message).to eq('the server responded with status 404 for GET http://example.com/test') }
    end
  end
end
