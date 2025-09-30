# frozen_string_literal: true

class TemplateService
  def initialize(template, user, params = {})
    @template = template
    @user = user
    @params = params
  end

  def assign_ownership
    if @params[:external_partnership_id].present?
      partnership = Partnership.find_by(external_partnership_id: @params[:external_partnership_id])
      raise ArgumentError, "Partnership not found: #{@params[:external_partnership_id]}" unless partnership

      @template.partnership = partnership
      @template.folder = TemplateFolders.find_or_create_by_name(@user, @params[:folder_name], partnership: partnership)
    elsif @params[:external_account_id].present?
      account = Account.find_by(external_account_id: @params[:external_account_id])
      raise ArgumentError, "Account not found: #{@params[:external_account_id]}" unless account

      @template.account = account
      @template.folder = TemplateFolders.find_or_create_by_name(@user, @params[:folder_name])
    elsif @user.account.present?
      @template.account = @user.account
      @template.folder = TemplateFolders.find_or_create_by_name(@user, @params[:folder_name])
    end
  end
end
