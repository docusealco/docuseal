# frozen_string_literal: true

# == Schema Information
#
# Table name: partnerships
#
#  id                      :bigint           not null, primary key
#  name                    :string           not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  external_partnership_id :integer          not null
#
# Indexes
#
#  index_partnerships_on_external_partnership_id  (external_partnership_id) UNIQUE
#
class Partnership < ApplicationRecord
  has_many :templates, dependent: :destroy
  has_many :template_folders, dependent: :destroy
  has_many :webhook_urls, dependent: :destroy

  validates :external_partnership_id, presence: true, uniqueness: true
  validates :name, presence: true

  after_commit :create_careerplug_webhook, on: :create

  def self.find_or_create_by_external_id(external_id, name, attributes = {})
    find_by(external_partnership_id: external_id) ||
      create!(attributes.merge(external_partnership_id: external_id, name: name))
  end

  def default_template_folder(author)
    raise ArgumentError, 'Author is required for partnership template folders' unless author

    template_folders.find_by(name: TemplateFolder::DEFAULT_NAME) ||
      template_folders.create!(name: TemplateFolder::DEFAULT_NAME,
                               author: author)
  end

  def create_careerplug_webhook
    return if ENV['CAREERPLUG_WEBHOOK_SECRET'].blank? || ENV['CAREERPLUG_WEBHOOK_URL'].blank?

    webhook_urls.create!(
      url: ENV.fetch('CAREERPLUG_WEBHOOK_URL'),
      events: %w[template.preferences_updated],
      secret: { 'X-CareerPlug-Secret' => ENV.fetch('CAREERPLUG_WEBHOOK_SECRET') }
    )
  end
end
