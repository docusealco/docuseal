# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TemplateService do
  describe '#assign_ownership' do
    let(:template) { build(:template, account: nil, account_group: nil) }
    let(:params) { { folder_name: 'Custom Folder' } }

    context 'with account_group user' do
      let(:account_group) { create(:account_group) }
      let(:user) { create(:user, account: nil, account_group: account_group) }

      it 'assigns account_group and default folder' do
        service = described_class.new(template, user, params)
        service.assign_ownership

        expect(template.account_group).to eq(account_group)
        expect(template.folder).to eq(account_group.default_template_folder)
      end
    end

    context 'with account user' do
      let(:account) { create(:account) }
      let(:user) { create(:user, account: account, account_group: nil) }

      it 'assigns account and finds/creates folder' do
        service = described_class.new(template, user, params)
        service.assign_ownership

        expect(template.account).to eq(account)
        expect(template.folder).to be_present
      end
    end

    context 'with user having neither account nor account_group' do
      let(:user) { build(:user, account: nil, account_group: nil) }

      it 'does not assign ownership' do
        service = described_class.new(template, user, params)
        service.assign_ownership

        expect(template.account).to be_nil
        expect(template.account_group).to be_nil
      end
    end
  end
end
