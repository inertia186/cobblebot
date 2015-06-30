class Admin::LinksController < Admin::AdminController
  before_filter :http_authenticate_feed, only: :index
  before_filter :authenticate_admin!
  before_filter :setup_params, only: :index
  
  def index
    @player_id = params[:player_id]

    if @player_id.present? && !!( @player = Player.find @player_id )
      @links = @player.links
    else
      @links = Link.all
    end

    timeframe
    query
    sort
    paginate
  end
  
  def show
    @link = Link.find(params[:id])
  end

  def destroy
    super Link, 'link', params[:id], admin_links_url, 'remove_link_row'
  end
private
  def timeframe
    @links = @links.where('links.created_at BETWEEN ? AND ?', Time.now.beginning_of_day, Time.now.end_of_day) if @filter == 'only_today'
  end
  
  def query
    if @query.present?
      q = "%#{@query}%"
      @links = @links.query(q)
    end
  end
  
  def sort
    case @sort_field
    when 'link_linked_by'
      @links = @links.select("links.*, lower(players.nick) AS link_linked_by").
        joins("LEFT OUTER JOIN players ON ( links.actor_type = 'Player' AND links.actor_id = players.id )").
        order("#{@sort_field} #{@sort_order}")
    else
      @links = @links.order("#{@sort_field} #{@sort_order}")
    end
  end
  
  def paginate
    @links = @links.paginate(page: params[:page], per_page: params[:per_page] || 25)
  end
end
