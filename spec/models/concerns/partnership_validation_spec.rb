# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PartnershipValidation do
  # Test with User model since it includes the concern
  describe 'validation' do
    context 'with account only' do
      it 'is valid' do
        user = build(:user, account: create(:account))
        expect(user).to be_valid
      end
    end
  end
end
