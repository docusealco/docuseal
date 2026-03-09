# frozen_string_literal: true

# == Schema Information
#
# Table name: dynamic_documents
#
#  id          :bigint           not null, primary key
#  body        :text             not null
#  head        :text
#  sha1        :text             not null
#  uuid        :uuid             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  template_id :bigint           not null
#
# Indexes
#
#  index_dynamic_documents_on_template_id  (template_id)
#
# Foreign Keys
#
#  fk_rails_...  (template_id => templates.id)
#
class DynamicDocument < ApplicationRecord
  belongs_to :template

  has_many_attached :attachments

  has_many :versions, class_name: 'DynamicDocumentVersion', dependent: :destroy

  attribute :fields, :json

  before_validation :set_sha1

  def set_sha1
    self.sha1 = Digest::SHA1.hexdigest(body)
  end
end
