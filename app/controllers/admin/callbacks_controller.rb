class Admin::CallbacksController < ApplicationController
  before_filter :authenticate_admin!

  def index
    @callbacks = ServerCallback.all
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
private
  def server_callback_params
    attributes = [:name, :pattern, :match_scheme, :command, :enabled]

    params.require(:server_callback).permit *attributes
  end
end