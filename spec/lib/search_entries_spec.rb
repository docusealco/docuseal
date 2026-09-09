# frozen_string_literal: true

RSpec.describe SearchEntries do
  describe '.index_template' do
    let(:user) { create(:user) }

    it 'does not rewrite an unchanged search entry' do
      template = create(
        :template,
        account: user.account,
        author: user,
        attachment_count: 0,
        name: 'Application 12-ab'
      )

      described_class.index_template(template)
      search_entry = template.search_entry.reload
      updated_at = search_entry.updated_at
      sql = []

      callback = lambda do |_name, _start, _finish, _id, payload|
        sql << payload[:sql]
      end

      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
        described_class.index_template(template.reload)
      end

      expect(search_entry.reload.updated_at).to eq(updated_at)
      expect(sql.grep(/UPDATE "search_entries"/)).to be_empty
    end

    it 'updates the search entry when the template name changes' do
      template = create(
        :template,
        account: user.account,
        author: user,
        attachment_count: 0,
        name: 'Original application'
      )

      described_class.index_template(template)
      original_tsvector = template.search_entry.reload.tsvector

      template.update!(name: 'Replacement agreement')
      described_class.index_template(template.reload)

      expect(template.search_entry.reload.tsvector).not_to eq(original_tsvector)
    end
  end
end
