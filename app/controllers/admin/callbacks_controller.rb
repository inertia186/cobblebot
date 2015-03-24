class Admin::CallbacksController < ApplicationController
  before_filter :authenticate_admin!

  def index
    @filter = params[:filter].present? ? params[:filter] : 'all'
    @query = params[:query]
    @status = params[:status]
    @match_scheme = params[:match_scheme]
    @sort_field = params[:sort_field].present? ? params[:sort_field] : 'created_at'
    @sort_order = params[:sort_order] == 'desc' ? 'desc' : 'asc'
    @callbacks = ServerCallback.all

    @callbacks = @callbacks.system if @filter == 'only_system'
    @callbacks = @callbacks.system(false) if @filter == 'exclude_system'
    
    if @query.present?
      q = "%#{@query}%"
      @callbacks = @callbacks.query(q)
    end

    if @status.present?
      case @status
      when 'ready'
        @callbacks = @callbacks.ready
      when 'in_cooldown'
        @callbacks = @callbacks.ready(false).enabled
      when 'enabled'
        @callbacks = @callbacks.enabled
      when 'disabled'
        @callbacks = @callbacks.enabled(false)
      end
    end

    if @match_scheme.present?
      @callbacks = @callbacks.match_scheme(@match_scheme)
    end
    
    case @sort_field
    when 'status'
      @callbacks = @callbacks.select('*, datetime(server_callbacks.ran_at, server_callbacks.cooldown) AS status').order("enabled #{@sort_order}, status #{@sort_order}")
    else
      @callbacks = @callbacks.order("#{@sort_field} #{@sort_order}")
    end
  end
  
  def reset_all_cooldown
    count = ServerCallback.dirty.update_all('last_match = NULL, last_command_output = NULL, ran_at = NULL')

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
      format.js { render 'replace_visible_callbacks' }
    end
  end

  def execute_command
    @callback = ServerCallback.find(params[:id])

    MinecraftServerLogHandler.execute_command(@callback, "@a", "Test")
    @callback.update_attribute(:last_match, 'Manual Run from Web Console')

    respond_to do |format|
      format.html { redirect_to admin_server_callbacks_url, notice: "Ran #{@callback.name} on all players." }
      format.js { render 'replace_visible_callbacks' }
    end
  end

  def reset_cooldown
    @callback = ServerCallback.find(params[:id])
    
    @callback.update_attributes(last_match: nil, last_command_output: nil, ran_at: nil)

    respond_to do |format|
      format.html { redirect_to admin_server_callbacks_url, notice: "Cooldown for #{@callback.name} has been reset." }
      format.js { render 'replace_visible_callbacks' }
    end
  end
private
  def server_callback_params
    attributes = [:name, :pattern, :match_scheme, :command, :cooldown, :enabled]

    params.require(:server_callback).permit *attributes
  end
end