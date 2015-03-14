class Admin::CallbacksController < ApplicationController
  before_filter :authenticate_admin!

  def index
    @callbacks = ServerCallback.all
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

    redirect_to admin_server_callbacks_url
  end
  
  def toggle_enabled
    @callback = ServerCallback.find(params[:id])
    
    @callback.update_attribute(:enabled, !@callback.enabled?)

    redirect_to admin_server_callbacks_url, notice: "#{@callback.name} is now #{@callback.enabled? ? 'Enabled' : 'Disabled'}."
  end

  def execute_command
    @callback = ServerCallback.find(params[:id])

    MinecraftServerLogHandler.execute_command(@callback, "@a", "Test")

    redirect_to admin_server_callbacks_url, notice: "Ran #{@callback.name} on all players."
  end

  def reset_cooldown
    @callback = ServerCallback.find(params[:id])
    
    @callback.update_attribute(:ran_at, nil)

    redirect_to admin_server_callbacks_url, notice: "Cooldown for #{@callback.name} has been reset."
  end
private
  def server_callback_params
    attributes = [:name, :pattern, :match_scheme, :command, :cooldown, :enabled]

    params.require(:server_callback).permit *attributes
  end
end