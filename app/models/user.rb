# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  deleted_at             :datetime
#  email                  :string           not null
#  encrypted_password     :string           not null
#  failed_attempts        :integer          default(0), not null
#  first_name             :string           not null
#  last_name              :string           not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  locked_at              :datetime
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  role                   :string           not null
#  sign_in_count          :integer          default(0), not null
#  unlock_token           :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :bigint           not null
#
# Indexes
#
#  index_users_on_account_id            (account_id)
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class User < ApplicationRecord
  ROLES = %w[admin].freeze

  EMAIL_REGEXP =
    /[a-z0-9][.']?(?:(?:[a-z0-9_-]++[.'])*[a-z0-9_-]++)*@(?:[a-z0-9]++[.-])*[a-z0-9]++\.[a-z]{2,}/i

  belongs_to :account

  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :trackable
  devise :registerable if Docuseal.multitenant?

  attribute :role, :string, default: 'admin'

  scope :active, -> { where(deleted_at: nil) }

  accepts_nested_attributes_for :account, update_only: true

  def active_for_authentication?
    !deleted_at?
  end

  def initials
    [first_name.first, last_name.first].join.upcase
  end

  def full_name
    [first_name, last_name].join(' ')
  end

  def friendly_name
    "#{full_name} <#{email}>"
  end
end
