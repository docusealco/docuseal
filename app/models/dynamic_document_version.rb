# frozen_string_literal: true

# == Schema Information
#
# Table name: dynamic_document_versions
#
#  id                  :bigint           not null, primary key
#  areas               :text             not null
#  sha1                :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  dynamic_document_id :bigint           not null
#
# Indexes
#
#  idx_on_dynamic_document_id_sha1_3503adf557  (dynamic_document_id,sha1) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (dynamic_document_id => dynamic_documents.id)
#
class DynamicDocumentVersion < ApplicationRecord
  belongs_to :dynamic_document

  has_one_attached :document

  attribute :areas, :string, default: -> { [] }

  serialize :areas, coder: JSON
end
