# frozen_string_literal: true

module PartnershipContext
  extend ActiveSupport::Concern

  private

  def current_ability
    @current_ability ||= Ability.new(current_user, partnership_request_context)
  end

  def partnership_request_context
    return nil if params[:accessible_partnership_ids].blank?

    {
      accessible_partnership_ids: Array.wrap(params[:accessible_partnership_ids]).map(&:to_i),
      external_account_id: params[:external_account_id],
      external_partnership_id: params[:external_partnership_id]
    }
  end
end
