# frozen_string_literal: true

describe PartnershipContext do
  # Create a test class that includes the concern
  let(:test_class) do
    Class.new do
      include PartnershipContext

      attr_accessor :params, :current_user

      def initialize(params = {}, user = nil)
        @params = params
        @current_user = user
      end
    end
  end

  let(:test_instance) { test_class.new(params) }

  describe '#partnership_request_context' do
    context 'when no partnership parameters are provided' do
      let(:params) { {} }

      it 'returns nil' do
        expect(test_instance.send(:partnership_request_context)).to be_nil
      end
    end

    context 'when accessible_partnership_ids is blank' do
      let(:params) { { accessible_partnership_ids: [] } }

      it 'returns nil' do
        expect(test_instance.send(:partnership_request_context)).to be_nil
      end
    end

    context 'when accessible_partnership_ids is nil' do
      let(:params) { { accessible_partnership_ids: nil } }

      it 'returns nil' do
        expect(test_instance.send(:partnership_request_context)).to be_nil
      end
    end

    context 'when partnership parameters are provided' do
      let(:params) do
        {
          accessible_partnership_ids: %w[123 456],
          external_account_id: 'ext-account-123',
          external_partnership_id: 'ext-partnership-456'
        }
      end

      it 'returns formatted partnership context' do
        expected_context = {
          accessible_partnership_ids: [123, 456],
          external_account_id: 'ext-account-123',
          external_partnership_id: 'ext-partnership-456'
        }

        expect(test_instance.send(:partnership_request_context)).to eq(expected_context)
      end

      it 'converts accessible_partnership_ids to integers' do
        result = test_instance.send(:partnership_request_context)
        expect(result[:accessible_partnership_ids]).to eq([123, 456])
        expect(result[:accessible_partnership_ids]).to all(be_an(Integer))
      end
    end

    context 'when only some parameters are provided' do
      let(:params) do
        {
          accessible_partnership_ids: ['123'],
          external_account_id: 'ext-account-123'
        }
      end

      it 'includes only provided parameters' do
        expected_context = {
          accessible_partnership_ids: [123],
          external_account_id: 'ext-account-123',
          external_partnership_id: nil
        }

        expect(test_instance.send(:partnership_request_context)).to eq(expected_context)
      end
    end

    context 'with string numbers' do
      let(:params) { { accessible_partnership_ids: %w[123 456] } }

      it 'converts string numbers to integers' do
        result = test_instance.send(:partnership_request_context)
        expect(result[:accessible_partnership_ids]).to eq([123, 456])
      end
    end
  end

  describe '#current_ability' do
    let(:user) { create(:user) }
    let(:partnership_context) do
      {
        accessible_partnership_ids: [123],
        external_account_id: 'ext-account-123',
        external_partnership_id: 'ext-partnership-456'
      }
    end
    let(:test_instance) { test_class.new({}, user) }

    before do
      allow(test_instance).to receive(:partnership_request_context).and_return(partnership_context)
    end

    it 'creates ability with partnership context' do
      allow(Ability).to receive(:new).and_call_original
      test_instance.send(:current_ability)
      expect(Ability).to have_received(:new).with(user, partnership_context)
    end

    it 'memoizes the ability instance' do
      allow(Ability).to receive(:new).and_call_original

      test_instance.send(:current_ability)
      test_instance.send(:current_ability) # Should use cached version

      expect(Ability).to have_received(:new).once
    end
  end
end
