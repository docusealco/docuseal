# frozen_string_literal: true

module TemplateFolders
  module_function

  def search(folders, keyword)
    return folders if keyword.blank?

    folders.where(TemplateFolder.arel_table[:name].lower.matches("%#{keyword.downcase}%"))
  end

  def find_or_create_by_name(author, name, partnership: nil)
    return default_folder(author, partnership) if name.blank? || name == TemplateFolder::DEFAULT_NAME

    if partnership.present?
      partnership.template_folders.create_with(author:, partnership:).find_or_create_by(name:)
    else
      author.account.template_folders.create_with(author:, account: author.account).find_or_create_by(name:)
    end
  end

  def default_folder(author, partnership)
    partnership.present? ? partnership.default_template_folder(author) : author.account.default_template_folder
  end
end
