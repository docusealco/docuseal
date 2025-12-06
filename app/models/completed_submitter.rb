# frozen_string_literal: true

# == Schema Information
#
# Table name: completed_submitters
#
#  id                  :bigint           not null, primary key
#  completed_at        :datetime         not null
#  is_first            :boolean
#  sms_count           :integer          not null
#  source              :string           not null
#  verification_method :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :bigint           not null
#  submission_id       :bigint           not null
#  submitter_id        :bigint           not null
#  template_id         :bigint
#
# Indexes
#
#  index_completed_submitters_account_id_completed_at_is_first  (account_id,completed_at) WHERE (is_first = true)
#  index_completed_submitters_on_account_id_and_completed_at    (account_id,completed_at)
#  index_completed_submitters_on_submission_id                  (submission_id) UNIQUE WHERE (is_first = true)
#  index_completed_submitters_on_submitter_id                   (submitter_id) UNIQUE
#
class CompletedSubmitter < ApplicationRecord
  belongs_to :submitter
  belongs_to :submission
  belongs_to :account
  belongs_to :template, optional: true

  has_many :completed_documents, dependent: :destroy,
                                 primary_key: :submitter_id,
                                 foreign_key: :submitter_id,
                                 inverse_of: :completed_submitter
end
