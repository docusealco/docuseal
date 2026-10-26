# frozen_string_literal: true

class SearchController < ApplicationController
  load_and_authorize_resource :template_folder, parent: false
  load_and_authorize_resource :template, parent: false
  load_and_authorize_resource :submission, parent: false
  load_and_authorize_resource :template, instance_name: :filter_template, id_param: :template_id, parent: true

  FOLDERS_LIMIT = 4
  LIMIT = 12

  def index
    @query = params[:q].to_s.squish

    return render_infinite_scroll(@template_folders, @templates, @submissions, @query) if turbo_infinite_scroll?

    if @query.blank?
      @template_folders = @templates = @submissions = []
    elsif params[:scope] == 'folders'
      @folders_pagy, @template_folders =
        pagy(:countless, filter_folders(@template_folders, @templates, @query), limit: LIMIT)

      @templates = @submissions = []
    else
      folders = filter_folders(@template_folders, @templates, @query)

      @pagy, @template_folders, @templates, @submissions =
        if params[:scope] == 'submissions'
          load_submissions_page(folders, @templates, @submissions, @query)
        else
          load_templates_page(folders, @templates, @submissions, @query)
        end

      if @templates.blank? && @submissions.blank? && params[:template_id].blank?
        @folders_pagy, @template_folders = pagy(:countless, folders, limit: LIMIT)
      end
    end
  end

  private

  def load_submissions_page(folders, templates, submissions, query)
    pagy, submissions = pagy(:countless, filter_submissions(submissions, query), limit: LIMIT)

    return [pagy, [], [], submissions] if pagy.next || params[:template_id].present?

    [pagy, folders.limit(FOLDERS_LIMIT).to_a, filter_templates(templates, query).limit(LIMIT).to_a, submissions]
  end

  def load_templates_page(folders, templates, submissions, query)
    pagy, templates = pagy(:countless, filter_templates(templates, query), limit: LIMIT)

    submissions = pagy.next ? [] : filter_submissions(submissions, query).limit(LIMIT).to_a

    [pagy, folders.limit(FOLDERS_LIMIT).to_a, templates, submissions]
  end

  def render_infinite_scroll(folders, templates, submissions, query)
    target, partial, collection =
      case params[:scope]
      when 'folders'
        ['search_folders', 'search/folder', filter_folders(folders, templates, query)]
      when 'submissions'
        ['search_submissions', 'search/submission', filter_submissions(submissions, query)]
      else
        ['search_templates', 'search/template', filter_templates(templates, query)]
      end

    pagy, records = pagy(:countless, collection, limit: LIMIT)

    render turbo_stream: [
      turbo_stream.append(target, partial:, collection: records),
      turbo_stream.replace('infinite_scroll', partial: 'shared/infinite_scroll', locals: { pagy: })
    ]
  end

  def filter_folders(folders, templates, query)
    return folders.none if params[:archived] == 'true'

    folders = folders.where.not(id: current_account.default_template_folder.id)

    folders = folders.where(parent_folder_id: filter_folder_ids(params[:folder])) if params[:folder].present?
    folders = folders.where(author_id: filter_author_id(params[:author])) if params[:author].present?
    folders = TemplateFolders.filter_active_folders(folders, templates)
    folders = TemplateFolders.search(folders, query)

    folders.preload(:parent_folder).order(:name)
  end

  def filter_templates(templates, query)
    templates = params[:archived] == 'true' ? templates.where.not(archived_at: nil) : templates.active
    templates = templates.select_for_list.preload(:author, :template_accesses, folder: :parent_folder)

    templates = templates.where(folder_id: filter_folder_ids(params[:folder])) if params[:folder].present?
    templates = templates.where(author_id: filter_author_id(params[:author])) if params[:author].present?

    Templates.search(current_user, templates, query).order(id: :desc)
  end

  def filter_folder_ids(folder_name)
    TemplateFolders.filter_by_full_name(current_account.template_folders, folder_name)
                   .preload(:subfolders)
                   .flat_map { |folder| [folder.id, *folder.subfolders.map(&:id)] }
  end

  def filter_author_id(email)
    current_account.users.find_by(email:)&.id || -1
  end

  def filter_submissions(submissions, query)
    submissions = submissions.left_joins(:template)

    submissions =
      if params[:archived] == 'true'
        submissions.where.not(archived_at: nil).or(submissions.where.not(templates: { archived_at: nil }))
      else
        submissions.where(archived_at: nil).where(templates: { archived_at: nil })
      end

    submissions = Submissions.search(current_user, submissions, query, search_template: true)
    submissions = Submissions::Filter.call(submissions, current_user, params)

    submissions =
      if params[:status] == 'completed' || params[:completed_at_from].present? || params[:completed_at_to].present?
        submissions.order(completed_at: :desc)
      else
        submissions.order(id: :desc)
      end

    submissions.select_for_list.preload(:submitters, :template)
  end
end
