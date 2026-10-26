# frozen_string_literal: true

# == Schema Information
#
# Table name: otp_challenges
#
#  id          :bigint           not null, primary key
#  attempts    :integer          default(0), not null
#  expire_at   :datetime         not null
#  key         :string           not null
#  nonce       :string           not null
#  verified_at :datetime
#  version     :integer          not null
#  created_at  :datetime         not null
#
# Indexes
#
#  index_otp_challenges_on_key_and_version  (key,version) UNIQUE
#
class OtpChallenge < ApplicationRecord
end
