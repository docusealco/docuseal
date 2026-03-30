# frozen_string_literal: true

# == Schema Information
#
# Table name: submitter_versions
#
#  id           :bigint           not null, primary key
#  email        :string
#  name         :string
#  phone        :string
#  slug         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  submitter_id :bigint           not null
#
# Indexes
#
#  index_submitter_versions_on_slug          (slug)
#  index_submitter_versions_on_submitter_id  (submitter_id)
#
# Foreign Keys
#
#  fk_rails_...  (submitter_id => submitters.id)
#
class SubmitterVersion < ApplicationRecord
  belongs_to :submitter
end
