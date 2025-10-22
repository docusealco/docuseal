# frozen_string_literal: true

describe Templates::Clone do
  describe '.call' do
    let(:author) { build(:user, id: 1) }
    let(:original_template) do
      build(
        :template,
        id: 1,
        name: 'Original',
        submitters: [],
        fields: [],
        schema: [],
        preferences: {}
      )
    end

    it 'requires either target_account or target_partnership' do
      expect do
        described_class.call(original_template, author: author)
      end.to raise_error(ArgumentError, 'Either target_account or target_partnership must be provided')
    end

    it 'creates template with target_account' do
      target_account = build(:account, id: 2)

      result = described_class.call(original_template, author: author, target_account: target_account)

      expect(result).to be_a(Template)
      expect(result.account).to eq(target_account)
      expect(result.partnership).to be_nil
      expect(result.author).to eq(author)
    end

    it 'creates template with target_partnership' do
      target_partnership = create(:partnership)

      result = described_class.call(original_template, author: author, target_partnership: target_partnership)

      expect(result).to be_a(Template)
      expect(result.partnership).to eq(target_partnership)
      expect(result.account).to be_nil
      expect(result.author).to eq(author)
    end

    it 'sets custom name when provided' do
      target_account = build(:account, id: 2)

      result = described_class.call(
        original_template,
        author: author,
        target_account: target_account,
        name: 'Custom Name'
      )

      expect(result.name).to eq('Custom Name')
    end

    it 'generates default clone name when no name provided' do
      target_account = build(:account, id: 2)
      allow(I18n).to receive(:t).with('clone').and_return('Clone')

      result = described_class.call(original_template, author: author, target_account: target_account)

      expect(result.name).to eq('Original (Clone)')
    end
  end
end
