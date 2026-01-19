# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FeatureFlagCheck, type: :controller do
  controller(ApplicationController) do
    include FeatureFlagCheck

    require_feature :test_feature

    def index
      render json: { message: 'success' }
    end
  end

  before do
    routes.draw { get 'index' => 'anonymous#index' }
  end

  describe 'require_feature' do
    context 'when feature is enabled' do
      before { allow(FeatureFlag).to receive(:enabled?).with(:test_feature).and_return(true) }

      it 'allows the action to proceed' do
        get :index
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['message']).to eq('success')
      end
    end

    context 'when feature is disabled' do
      before { allow(FeatureFlag).to receive(:enabled?).with(:test_feature).and_return(false) }

      it 'returns 404 not found' do
        get :index
        expect(response).to have_http_status(:not_found)
      end

      it 'returns error message' do
        get :index
        expect(JSON.parse(response.body)['error']).to eq('Feature not available')
      end
    end
  end

  describe '#feature_enabled?' do
    controller(ApplicationController) do
      include FeatureFlagCheck

      def check_feature
        render json: { enabled: feature_enabled?(:test_feature) }
      end
    end

    before do
      routes.draw { get 'check_feature' => 'anonymous#check_feature' }
    end

    it 'returns true when feature is enabled' do
      allow(FeatureFlag).to receive(:enabled?).with(:test_feature).and_return(true)
      get :check_feature
      expect(JSON.parse(response.body)['enabled']).to be true
    end

    it 'returns false when feature is disabled' do
      allow(FeatureFlag).to receive(:enabled?).with(:test_feature).and_return(false)
      get :check_feature
      expect(JSON.parse(response.body)['enabled']).to be false
    end
  end
end
