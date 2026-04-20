# frozen_string_literal: true

# == Schema Information
#
# Table name: document_metadata
#
#  id            :bigint           not null, primary key
#  blob_checksum :string           not null
#  text_runs     :text             not null
#  created_at    :datetime         not null
#  account_id    :bigint           not null
#
# Indexes
#
#  index_document_metadata_on_account_id_and_blob_checksum  (account_id,blob_checksum) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class DocumentMetadata < ApplicationRecord
  belongs_to :account

  attribute :text_runs, :string, default: -> { {} }

  serialize :text_runs, coder: JSON
end
