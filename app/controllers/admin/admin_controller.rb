class Admin::AdminController < ApplicationController
  helper_method :sign_in_admin
  helper_method :setup_params
private
  def setup_params
    @filter = params[:filter].present? ? params[:filter] : 'all'
    @query = params[:query]
    @sort_field = params[:sort_field].present? ? params[:sort_field] : 'created_at'
    @sort_order = params[:sort_order] == 'asc' ? 'asc' : 'desc'
  end

  def destroy(clazz, assign, id, return_to, js_template)
    object = clazz.find(params[:id])
    object.destroy
    instance_variable_set "@#{assign}", object

    respond_to do |format|
      format.html { redirect_to return_to }
      format.js { render js_template }
    end
  end

  def sign_in_admin
    session[:admin_signed_in] = true
  end
end