class Admin::CallbacksController < ApplicationController
  before_filter :authenticate_admin!

  def index
    @callbacks = ServerCallback.all.order(:created_at)
  end
  
  def reset_all_cooldown
    count = ServerCallback.where.not(id: ServerCallback.ready).update_all('ran_at = NULL')

    redirect_to admin_server_callbacks_url, notice: "#{pluralize count, "Callback"} reset."
  end

  def show
    @callback = ServerCallback.find(params[:id])
  end
  
  def new
    @callback = ServerCallback.new
  end
  
  def edit
    @callback = ServerCallback.find(params[:id])
  end
  
  def create
    @callback = ServerCallback.new(server_callback_params)

    if @callback.save
      redirect_to admin_server_callbacks_url
    else
      render action: 'new'
    end
  end
  
  def update
    @callback = ServerCallback.find(params[:id])

    if @callback.update_attributes(server_callback_params)
      redirect_to admin_server_callbacks_url
    else
      render action: 'edit'
    end
  end
  
  def destroy
    @callback = ServerCallback.find(params[:id])

    @callback.destroy

    respond_to do |format|
      format.html { redirect_to admin_server_callbacks_url }
      format.js { render 'remove_callback_row' }
    end
  end
  
  def toggle_enabled
    @callback = ServerCallback.find(params[:id])
    
    @callback.update_attribute(:enabled, !@callback.enabled?)

    respond_to do |format|
      format.html { redirect_to admin_server_callbacks_url, notice: "#{@callback.name} is now #{@callback.enabled? ? 'Enabled' : 'Disabled'}." }
      format.js { render 'replace_callback_row' }
    end
  end

  def execute_command
    @callback = ServerCallback.find(params[:id])

    MinecraftServerLogHandler.execute_command(@callback, "@a", "Test")

    respond_to do |format|
      format.html { redirect_to admin_server_callbacks_url, notice: "Ran #{@callback.name} on all players." }
      format.js { render 'replace_callback_row' }
    end
  end

  def reset_cooldown
    @callback = ServerCallback.find(params[:id])
    
    @callback.update_attribute(:ran_at, nil)

    respond_to do |format|
      format.html { redirect_to admin_server_callbacks_url, notice: "Cooldown for #{@callback.name} has been reset." }
      format.js { render 'replace_callback_row' }
    end
  end
private
  def server_callback_params
    attributes = [:name, :pattern, :match_scheme, :command, :cooldown, :enabled]

    params.require(:server_callback).permit *attributes
  end
end