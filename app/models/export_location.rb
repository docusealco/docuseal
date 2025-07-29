# frozen_string_literal: true

# == Schema Information
#
# Table name: export_locations
#
#  id                   :bigint           not null, primary key
#  api_base_url         :string           not null
#  authorization_token  :string
#  default_location     :boolean          default(FALSE), not null
#  extra_params         :jsonb            not null
#  name                 :string           not null
#  submissions_endpoint :string
#  templates_endpoint   :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
class ExportLocation < ApplicationRecord
  validates :name, presence: true
  validates :api_base_url, presence: true

  def self.default_location
    where(default_location: true).first || ExportLocation.first
  end
end
