# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TokenRefreshService do
  describe '#refresh_token' do
    let(:user_params) do
      {
        user: {
          external_id: 123,
          email: 'test@example.com',
          first_name: 'John',
          last_name: 'Doe'
        }
      }
    end

    context 'when user exists' do
      let!(:user) { create(:user, external_user_id: 123) }

      it 'destroys existing token and creates new one' do
        original_token = user.access_token.token
        original_token_id = user.access_token.id

        new_token = described_class.new(user_params).refresh_token

        expect(new_token).to be_present
        expect(new_token).not_to eq(original_token)

        # Verify the original access token was actually destroyed
        expect(AccessToken.find_by(id: original_token_id)).to be_nil

        # Verify user has a new access token
        user.reload
        expect(user.access_token).to be_present
        expect(user.access_token.token).to eq(new_token)
        expect(user.access_token.id).not_to eq(original_token_id)
      end

      it 'handles user without existing access token' do
        user.access_token.destroy

        new_token = described_class.new(user_params).refresh_token

        expect(new_token).to be_present
        expect(user.reload.access_token).to be_present
      end
    end

    context 'when user does not exist' do
      it 'returns nil' do
        result = described_class.new(user_params).refresh_token

        expect(result).to be_nil
      end
    end

    context 'with invalid params' do
      it 'returns nil when external_id is missing' do
        invalid_params = { user: { email: 'test@example.com' } }

        result = described_class.new(invalid_params).refresh_token

        expect(result).to be_nil
      end
    end
  end
end
