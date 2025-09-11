# frozen_string_literal: true

class TemplateService
  def initialize(template, user, params = {})
    @template = template
    @user = user
    @params = params
  end

  def assign_ownership
    if @user.account_group.present?
      @template.account_group = @user.account_group
      @template.folder = @user.account_group.default_template_folder
    elsif @user.account.present?
      @template.account = @user.account
      @template.folder = TemplateFolders.find_or_create_by_name(@user, @params[:folder_name])
    end
  end
end
