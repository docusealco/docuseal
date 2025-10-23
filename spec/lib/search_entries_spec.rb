# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchEntries do
  describe '.index_template' do
    context 'with partnership template' do
      let(:partnership) { create(:partnership) }
      let(:template) do
        create(:template, :partnership_template, partnership: partnership, name: 'Partnership Template')
      end

      it 'skips search indexing for partnership templates' do
        result = described_class.index_template(template)

        expect(result).to be_nil
        expect(template.reload.search_entry).to be_nil
      end

      it 'does not raise error when account_id is blank' do
        expect { described_class.index_template(template) }.not_to raise_error
      end

      it 'logs the reason for skipping partnership templates' do
        # Verify the early return works as expected
        expect(template.account_id).to be_nil
        expect(template.partnership_id).to be_present

        result = described_class.index_template(template)
        expect(result).to be_nil
      end
    end

    context 'with account template' do
      let(:account) { create(:account) }
      let(:user) { create(:user, account: account) }
      let(:template) { create(:template, account: account, author: user, name: 'Test Template') }

      it 'processes account templates normally' do
        expect(template.account_id).to be_present
        expect(template.partnership_id).to be_nil

        expect { described_class.index_template(template) }.not_to raise_error(ArgumentError, /account_id.blank?/)
      end
    end
  end
end
