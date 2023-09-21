# frozen_string_literal: true

module TemplateFolders
  module_function

  def search(folders, keyword)
    return folders if keyword.blank?

    folders.where(TemplateFolder.arel_table[:name].lower.matches("%#{keyword.downcase}%"))
  end

  def find_or_create_by_name(author, name)
    return author.account.default_template_folder if name.blank? || name == TemplateFolder::DEFAULT_NAME

    author.account.template_folders.create_with(author:, account: author.account).find_or_create_by(name:)
  end
end
