# frozen_string_literal: true

# Bridges Clerk's apex-cookie SSO into Devise. When a request arrives with a
# valid Clerk session JWT belonging to the Bloombilt Staff org, find or
# auto-provision the matching Devise User and call sign_in so the rest of the
# app (which authorizes via Devise + CanCanCan) sees the request as
# authenticated. Devise's password login at /users/sign_in is preserved as
# emergency access.
module ClerkDeviseBridge
  extend ActiveSupport::Concern

  STAFF_ORG_SLUG = 'bloombilt-staff'

  included do
    before_action :sign_in_from_clerk_session, unless: :devise_controller?
  end

  private

  def sign_in_from_clerk_session
    return if user_signed_in?

    clerk_user = safe_clerk_user
    return unless clerk_user

    return unless clerk.organization&.slug == STAFF_ORG_SLUG

    email = primary_email(clerk_user)
    return unless email

    user = User.active.find_by(email: email) || provision_user_for_clerk(email, clerk_user)
    return unless user

    sign_in(user, store: true)
  end

  def safe_clerk_user
    clerk.user
  rescue StandardError => e
    Rails.logger.warn("[clerk-bridge] reading clerk.user failed: #{e.class}: #{e.message}")
    nil
  end

  def primary_email(clerk_user)
    addresses = clerk_user.respond_to?(:email_addresses) ? clerk_user.email_addresses : nil
    addresses&.first&.email_address&.to_s&.downcase.presence
  end

  def provision_user_for_clerk(email, clerk_user)
    first_name = clerk_user.respond_to?(:first_name) ? clerk_user.first_name : nil
    last_name = clerk_user.respond_to?(:last_name) ? clerk_user.last_name : nil

    User.provision_clerk_admin(email: email, first_name: first_name, last_name: last_name)
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
    Rails.logger.warn("[clerk-bridge] provision failed for #{email}: #{e.message}")
    User.active.find_by(email: email)
  end
end
