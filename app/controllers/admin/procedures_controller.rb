class Admin::ProceduresController < AdminController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  before_action :retrieve_procedure, only: [:show, :delete_logo, :delete_deliberation, :delete_notice, :publish_validate, :publish]

  def index
    if current_administrateur.procedures.count != 0
      @procedures = smart_listing_create :procedures,
        current_administrateur.procedures.publiees.order(published_at: :desc),
        partial: "admin/procedures/list",
        array: true

      active_class
    else
      redirect_to new_from_existing_admin_procedures_path
    end
  end

  def show
    if @procedure.brouillon?
      @procedure_lien = commencer_test_url(path: @procedure.path)
    else
      @procedure_lien = commencer_url(path: @procedure.path)
    end
    @procedure.path = @procedure.suggested_path(current_administrateur)
    @current_administrateur = current_administrateur
  end

  def active_class
    @active_class = 'active'
  end

  def archived_class
    @archived_class = 'active'
  end

  def draft_class
    @draft_class = 'active'
  end

  private

  def cloned_from_library?
    params[:from_new_from_existing].present?
  end

  def publish_params
    params.permit(:path, :lien_site_web)
  end

  def procedure_params
    editable_params = [:libelle, :description, :organisation, :direction, :lien_site_web, :cadre_juridique, :deliberation, :notice, :web_hook_url, :euro_flag, :logo, :auto_archive_on]
    permited_params = if @procedure&.locked?
      params.require(:procedure).permit(*editable_params)
    else
      params.require(:procedure).permit(*editable_params, :duree_conservation_dossiers_dans_ds, :duree_conservation_dossiers_hors_ds, :for_individual, :path)
    end
    permited_params
  end
end
