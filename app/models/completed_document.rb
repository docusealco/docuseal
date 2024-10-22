# frozen_string_literal: true

# == Schema Information
#
# Table name: completed_documents
#
#  id           :bigint           not null, primary key
#  sha256       :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  submitter_id :bigint           not null
#
# Indexes
#
#  index_completed_documents_on_sha256        (sha256)
#  index_completed_documents_on_submitter_id  (submitter_id)
#
class CompletedDocument < ApplicationRecord
  belongs_to :submitter
end
