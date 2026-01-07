# frozen_string_literal: true

class TemplatesController < ApplicationController
  load_and_authorize_resource :template

  def show
    submissions = @template.submissions.accessible_by(current_ability)
    submissions = submissions.active if @template.archived_at.blank?
    submissions = Submissions.search(current_user, submissions, params[:q], search_values: true)
    submissions = Submissions::Filter.call(submissions, current_user, params.except(:status))

    @base_submissions = submissions

    submissions = Submissions::Filter.filter_by_status(submissions, params)

    submissions = if params[:completed_at_from].present? || params[:completed_at_to].present?
                    submissions.order(Submitter.arel_table[:completed_at].maximum.desc)
                  else
                    submissions.order(id: :desc)
                  end

    @pagy, @submissions = pagy_auto(submissions.preload(:template_accesses, submitters: :start_form_submission_events))
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path
  end

  def new; end

  def edit
    ActiveRecord::Associations::Preloader.new(
      records: [@template],
      associations: [schema_documents: [:blob, { preview_images_attachments: :blob }]]
    ).call

    @template_data =
      @template.as_json.merge(
        documents: @template.schema_documents.as_json(
          methods: %i[metadata signed_uuid],
          include: { preview_images: { methods: %i[url metadata filename] } }
        )
      ).to_json

    render :edit, layout: 'plain'
  end

  def create
    @template.author = current_user
    @template.folder = TemplateFolders.find_or_create_by_name(current_user, params[:folder_name])
    @template.account = current_account

    Templates.maybe_assign_access(@template)

    if @template.save
      SearchEntries.enqueue_reindex(@template)

      WebhookUrls.enqueue_events(@template, 'template.created')

      redirect_to(edit_template_path(@template))
    else
      render turbo_stream: turbo_stream.replace(:modal, template: 'templates/new'), status: :unprocessable_content
    end
  end

  def update
    @template.assign_attributes(template_params)

    is_name_changed = @template.name_changed?

    @template.save!

    SearchEntries.enqueue_reindex(@template) if is_name_changed

    WebhookUrls.enqueue_events(@template, 'template.updated')

    head :ok
  end

  def destroy
    notice =
      if params[:permanently].in?(['true', true])
        @template.destroy!

        I18n.t('template_has_been_removed')
      else
        @template.update!(archived_at: Time.current)

        I18n.t('template_has_been_archived')
      end

    redirect_back(fallback_location: root_path, notice:)
  end

  private

  def template_params
    params.require(:template).permit(
      :name,
      { schema: [[:attachment_uuid, :google_drive_file_id, :name,
                  { conditions: [%i[field_uuid value action operation]] }]],
        submitters: [%i[name uuid is_requester linked_to_uuid invite_by_uuid optional_invite_by_uuid email order]],
        fields: [[:uuid, :submitter_uuid, :name, :type,
                  :required, :readonly, :default_value,
                  :title, :description, :prefillable,
                  { preferences: {},
                    default_value: [],
                    conditions: [%i[field_uuid value action operation]],
                    options: [%i[value uuid]],
                    validation: %i[message pattern min max step],
                    areas: [%i[x y w h cell_w attachment_uuid option_uuid page]] }]] }
    )
  end
end
