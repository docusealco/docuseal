# frozen_string_literal: true

class SubmittersAutocompleteController < ApplicationController
  load_and_authorize_resource :submitter, parent: false

  SELECT_COLUMNS = %w[email phone name].freeze
  LIMIT = 100

  def index
    submitters = search_submitters(@submitters)

    arel_columns = SELECT_COLUMNS.map { |col| Submitter.arel_table[col] }

    values =
      if params[:field].present? && SELECT_COLUMNS.include?(params[:field])
        max_ids = submitters.group(params[:field]).limit(LIMIT).select(Submitter.arel_table[:id].maximum)

        submitters.where(id: max_ids).order(id: :desc).pluck(arel_columns)
      else
        submitters.limit(LIMIT).group(arel_columns).pluck(arel_columns)
      end

    attrs = values.map { |row| SELECT_COLUMNS.zip(row).to_h }

    render json: attrs
  end

  private

  def search_submitters(submitters)
    if SELECT_COLUMNS.include?(params[:field])
      if Docuseal.fulltext_search?
        Submitters.fulltext_search_field(current_user, submitters, params[:q], params[:field])
      else
        column = Submitter.arel_table[params[:field].to_sym]

        term = "#{params[:q].downcase}%"

        submitters.where(column.matches(term))
      end
    else
      Submitters.search(current_user, submitters, params[:q])
    end
  end
end
