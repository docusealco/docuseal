# frozen_string_literal: true

class Team < ApplicationRecord
  belongs_to :account

  has_many :users, dependent: :nullify
  has_many :templates, dependent: :nullify
  has_many :submissions, dependent: :nullify
  has_many :submitters, dependent: :nullify
  has_many :template_folders, dependent: :nullify

  attribute :uuid, :string, default: -> { SecureRandom.uuid }

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  validates :name, presence: true
end
