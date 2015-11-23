class Admin::AdminController < ApplicationController
  helper_method :sign_in_admin
  helper_method :best_actor_name
private
  def destroy(clazz, assign, id, return_to, js_template)
    object = clazz.find(params[:id])
    object.destroy
    instance_variable_set "@#{assign}", object

    respond_to do |format|
      format.html { redirect_to return_to, notice: "#{clazz} deleted." }
      format.js { render js_template }
    end
  end

  def sign_in_admin
    session[:admin_signed_in] = true
  end
  
  def best_actor_name(actor_type, actor)
    return 'N/A' unless actor_type == 'Player'
    return '[REDACTED]' if actor.nil?

    actor.nick rescue '[REDACTED]'
  end
end