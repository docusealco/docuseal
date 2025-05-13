class DocumentsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    file = params[:file]

    if file
      render json: {
        message: "Fichier reçu avec succès.",
        nom: file.original_filename,
        taille: file.size
      }, status: :ok
    else
      render json: { error: "Aucun fichier reçu" }, status: :unprocessable_entity
    end
  end
end
