require 'digest/md5'

class Admin::PlayersController < Admin::AdminController
  before_filter :authenticate_admin!
  
  def index
    @filter = params[:filter].present? ? params[:filter] : 'all'
    @query = params[:query]
    @sort_field = params[:sort_field].present? ? params[:sort_field] : 'last_login_at'
    @sort_order = params[:sort_order] == 'asc' ? 'asc' : 'desc'
    
    @players = Player.all

    @players = @players.where('players.last_login_at BETWEEN ? AND ?', Time.now.beginning_of_day, Time.now.end_of_day) if @filter == 'only_today'
    @players = Server.players if @filter == 'only_logged_in'
    
    if @query.present?
      @players = @players.query(@query)
    end
    
    case @sort_field
    when 'links_count'
      @players = @players.select("players.*, ( SELECT COUNT(*) FROM links WHERE players.id = links.actor_id AND links.actor_type = 'Player') AS links_count").
        order("#{@sort_field} #{@sort_order}")
    else
      @players = @players.order("#{@sort_field} #{@sort_order}")
    end
    
    @players = @players.paginate(page: params[:page], per_page: 100)
  end
  
  def show
    @player = Player.find(params[:id])
  end

  def destroy
    super Player, 'player', params[:id], admin_players_url, 'remove_player_row'
  end
end
