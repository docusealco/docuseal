# frozen_string_literal: true

module OtpChallenges
  CODE_TTL = 10.minutes
  REUSE_MIN_TTL = 5.minutes
  MAX_ATTEMPTS = 20
  MAX_TOTAL_ATTEMPTS = 100
  ATTEMPTS_WINDOW = 23.hours

  module_function

  def generate(value, purpose:)
    key = build_key(value, purpose)
    latest_challenge = OtpChallenge.where(key:).order(version: :desc).first

    otp_challenge =
      if latest_challenge && !latest_challenge.verified_at? && latest_challenge.expire_at > REUSE_MIN_TTL.from_now
        latest_challenge
      else
        version = latest_challenge ? latest_challenge.version + 1 : 1

        OtpChallenge.create_with(nonce: SecureRandom.base58(16), expire_at: CODE_TTL.from_now)
                    .create_or_find_by!(key:, version:)
      end

    build_hotp(value, purpose, otp_challenge.nonce).at(0)
  end

  def verify(code, value, purpose:)
    challenges = OtpChallenge.where(key: build_key(value, purpose))

    recent_challenges = challenges.where(expire_at: ATTEMPTS_WINDOW.ago..).order(version: :desc).to_a

    latest_challenge = recent_challenges.first

    return false if latest_challenge.nil? || latest_challenge.verified_at? || latest_challenge.expire_at.past?

    raise RateLimit::LimitApproached if recent_challenges.sum(&:attempts) >= MAX_ATTEMPTS
    raise RateLimit::LimitApproached if challenges.sum(:attempts) >= MAX_TOTAL_ATTEMPTS

    if build_hotp(value, purpose, latest_challenge.nonce).verify(code.to_s, 0)
      OtpChallenge.where(id: latest_challenge.id, verified_at: nil).update_all(verified_at: Time.current) == 1
    else
      latest_challenge.increment!(:attempts)

      OtpChallenge.current_transaction.after_rollback { OtpChallenge.update_counters(latest_challenge.id, attempts: 1) }

      false
    end
  end

  def build_key(value, purpose)
    Digest::SHA256.hexdigest([purpose, value].join(':'))
  end

  def build_hotp(value, purpose, nonce)
    ROTP::HOTP.new(
      ROTP::Base32.encode(
        Digest::SHA1.digest([Rails.application.secret_key_base, purpose, value, nonce].join(':'))
      )
    )
  end
end
