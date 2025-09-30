# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TemplateService do
  describe '#assign_ownership' do
    let(:template) { build(:template, account: nil, partnership: nil) }
    let(:params) { { folder_name: 'Custom Folder' } }

    context 'with partnership user' do
      let(:partnership) { create(:partnership) }
      let(:user) { create(:user, account: nil) }
      let(:params) { { folder_name: 'Custom Folder', external_partnership_id: partnership.external_partnership_id } }

      it 'assigns partnership and creates custom folder' do
        service = described_class.new(template, user, params)
        service.assign_ownership

        expect(template.partnership).to eq(partnership)
        expect(template.folder.name).to eq('Custom Folder')
        expect(template.folder.partnership).to eq(partnership)
      end
    end

    context 'with account user' do
      let(:account) { create(:account) }
      let(:user) { create(:user, account: account) }

      it 'assigns account and finds/creates folder' do
        service = described_class.new(template, user, params)
        service.assign_ownership

        expect(template.account).to eq(account)
        expect(template.folder).to be_present
      end
    end

    context 'with user having neither account nor partnership' do
      let(:user) { build(:user, account: nil) }

      it 'does not assign ownership' do
        service = described_class.new(template, user, params)
        service.assign_ownership

        expect(template.account).to be_nil
        expect(template.partnership).to be_nil
      end
    end
  end
end
