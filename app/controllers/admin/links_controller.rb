class Admin::LinksController < ApplicationController
  before_filter :authenticate_admin!
  
  def index
    @filter = params[:filter].present? ? params[:filter] : 'all'
    @query = params[:query]
    @status = params[:status]
    @match_scheme = params[:match_scheme]
    @sort_field = params[:sort_field].present? ? params[:sort_field] : 'created_at'
    @sort_order = params[:sort_order] == 'desc' ? 'desc' : 'asc'
    @player_id = params[:player_id]
    @player = Player.find @player_id if @player_id
    
    if @player
      @links = @player.links
    else
      @links = Link.all
    end

    @links = @links.where('links.created_at BETWEEN ? AND ?', Time.now.beginning_of_day, Time.now.end_of_day) if @filter == 'only_today'
    
    if @query.present?
      q = "%#{@query}%"
      @links = @links.query(q)
    end

    case @sort_field
    when
      sort_nulls = 
      @links = @links.select("links.*, lower(players.nick) AS link_linked_by").
        joins("LEFT OUTER JOIN players ON ( links.actor_type = 'Player' AND links.actor_id = players.id )").
        order("#{@sort_field} #{@sort_order}")
    else
      @links = @links.order("#{@sort_field} #{@sort_order}")
    end
  end
  
  def show
    @link = Link.find(params[:id])
  end

  def destroy
    @link = Link.find(params[:id])

    @link.destroy

    respond_to do |format|
      format.html { redirect_to admin_links_url }
      format.js { render 'remove_link_row' }
    end
  end
end
