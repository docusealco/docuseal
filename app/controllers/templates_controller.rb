# frozen_string_literal: true

class TemplatesController < ApplicationController
  load_and_authorize_resource :template

  before_action :load_base_template, only: %i[new create]

  def show
    submissions = @template.submissions.accessible_by(current_ability)
    submissions = submissions.active if @template.archived_at.blank?
    submissions = Submissions.search(submissions, params[:q])

    @base_submissions = submissions

    submissions = submissions.pending if params[:status] == 'pending'
    submissions = submissions.completed if params[:status] == 'completed'

    @pagy, @submissions = pagy(submissions.preload(:submitters).order(id: :desc))
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path
  end

  def new
    @template.name = "#{@base_template.name} (Clone)" if @base_template
  end

  def edit
    ActiveRecord::Associations::Preloader.new(
      records: [@template],
      associations: [schema_documents: { preview_images_attachments: :blob }]
    ).call

    @template_data =
      @template.as_json.merge(
        documents: @template.schema_documents.as_json(
          methods: [:metadata],
          include: { preview_images: { methods: %i[url metadata filename] } }
        )
      ).to_json

    render :edit, layout: 'plain'
  end

  def create
    if @base_template
      @template = Templates::Clone.call(@base_template, author: current_user,
                                                        name: params.dig(:template, :name),
                                                        folder_name: params[:folder_name])
    else
      @template.author = current_user
      @template.folder = TemplateFolders.find_or_create_by_name(current_user, params[:folder_name])
    end

    @template.account = current_account

    if @template.save
      Templates::CloneAttachments.call(template: @template, original_template: @base_template) if @base_template

      redirect_to edit_template_path(@template)
    else
      render turbo_stream: turbo_stream.replace(:modal, template: 'templates/new'), status: :unprocessable_entity
    end
  end

  def destroy
    notice =
      if params[:permanently].present?
        @template.destroy!

        Rollbar.info("Remove template: #{@template.id}") if defined?(Rollbar)

        'Template has been removed.'
      else
        @template.update!(archived_at: Time.current)

        'Template has been archived.'
      end

    redirect_back(fallback_location: root_path, notice:)
  end

  private

  def template_params
    params.require(:template).permit(:name)
  end

  def load_base_template
    return if params[:base_template_id].blank?

    @base_template = Template.accessible_by(current_ability).find_by(id: params[:base_template_id])
  end
end
