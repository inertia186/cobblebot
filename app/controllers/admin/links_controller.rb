class Admin::LinksController < Admin::AdminController
  before_filter :authenticate_admin!
  
  def index
    @filter = params[:filter].present? ? params[:filter] : 'all'
    @query = params[:query]
    @status = params[:status]
    @sort_field = params[:sort_field].present? ? params[:sort_field] : 'created_at'
    @sort_order = params[:sort_order] == 'asc' ? 'asc' : 'desc'
    @player_id = params[:player_id]
    @player = Player.find @player_id if @player_id.present?
    
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
    
    @links = @links.paginate(page: params[:page], per_page: 25)
  end
  
  def show
    @link = Link.find(params[:id])
  end

  def destroy
    super Link, 'link', params[:id], admin_links_url, 'remove_link_row'
  end
end
