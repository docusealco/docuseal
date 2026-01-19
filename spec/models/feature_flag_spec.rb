# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FeatureFlag, type: :model do
  describe 'validations' do
    subject { build(:feature_flag) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
  end

  describe '.enabled?' do
    context 'when feature flag exists and is enabled' do
      before { create(:feature_flag, name: 'test_feature', enabled: true) }

      it 'returns true' do
        expect(FeatureFlag.enabled?('test_feature')).to be true
      end

      it 'accepts symbol as parameter' do
        expect(FeatureFlag.enabled?(:test_feature)).to be true
      end
    end

    context 'when feature flag exists and is disabled' do
      before { create(:feature_flag, name: 'test_feature', enabled: false) }

      it 'returns false' do
        expect(FeatureFlag.enabled?('test_feature')).to be false
      end
    end

    context 'when feature flag does not exist' do
      it 'returns false' do
        expect(FeatureFlag.enabled?('nonexistent_feature')).to be false
      end
    end
  end

  describe '.enable!' do
    context 'when feature flag exists' do
      let!(:flag) { create(:feature_flag, name: 'test_feature', enabled: false) }

      it 'enables the feature flag' do
        expect { FeatureFlag.enable!('test_feature') }
          .to change { flag.reload.enabled }.from(false).to(true)
      end

      it 'returns true' do
        expect(FeatureFlag.enable!('test_feature')).to be true
      end
    end

    context 'when feature flag does not exist' do
      it 'creates and enables the feature flag' do
        expect { FeatureFlag.enable!('new_feature') }
          .to change(FeatureFlag, :count).by(1)

        expect(FeatureFlag.find_by(name: 'new_feature').enabled).to be true
      end
    end

    it 'accepts symbol as parameter' do
      FeatureFlag.enable!(:symbol_feature)
      expect(FeatureFlag.enabled?(:symbol_feature)).to be true
    end
  end

  describe '.disable!' do
    context 'when feature flag exists' do
      let!(:flag) { create(:feature_flag, name: 'test_feature', enabled: true) }

      it 'disables the feature flag' do
        expect { FeatureFlag.disable!('test_feature') }
          .to change { flag.reload.enabled }.from(true).to(false)
      end

      it 'returns true' do
        expect(FeatureFlag.disable!('test_feature')).to be true
      end
    end

    context 'when feature flag does not exist' do
      it 'creates and disables the feature flag' do
        expect { FeatureFlag.disable!('new_feature') }
          .to change(FeatureFlag, :count).by(1)

        expect(FeatureFlag.find_by(name: 'new_feature').enabled).to be false
      end
    end

    it 'accepts symbol as parameter' do
      FeatureFlag.disable!(:symbol_feature)
      expect(FeatureFlag.enabled?(:symbol_feature)).to be false
    end
  end

  describe 'default feature flags' do
    it 'includes flodoc_cohorts flag' do
      # This assumes migration has been run
      flag = FeatureFlag.find_by(name: 'flodoc_cohorts')
      expect(flag).to be_present
      expect(flag.enabled).to be true
    end

    it 'includes flodoc_portals flag' do
      # This assumes migration has been run
      flag = FeatureFlag.find_by(name: 'flodoc_portals')
      expect(flag).to be_present
      expect(flag.enabled).to be true
    end
  end
end
