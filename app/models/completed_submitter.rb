# frozen_string_literal: true

# == Schema Information
#
# Table name: completed_submitters
#
#  id            :bigint           not null, primary key
#  completed_at  :datetime         not null
#  sms_count     :integer          not null
#  source        :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#  submission_id :bigint           not null
#  submitter_id  :bigint           not null
#  template_id   :bigint
#
# Indexes
#
#  index_completed_submitters_on_account_id    (account_id)
#  index_completed_submitters_on_submitter_id  (submitter_id) UNIQUE
#
class CompletedSubmitter < ApplicationRecord
  belongs_to :submitter
  belongs_to :submission
  belongs_to :account
  belongs_to :template, optional: true

  has_many :completed_documents, dependent: :destroy,
                                 primary_key: :submitter_id,
                                 foreign_key: :submitter_id,
                                 inverse_of: :submitter
end
