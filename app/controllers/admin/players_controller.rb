require 'digest/md5'

class Admin::PlayersController < Admin::AdminController
  before_filter :authenticate_admin!
  before_filter :setup_params, only: :index
  
  def index
    @sort_field = params[:sort_field].present? ? params[:sort_field] : 'last_login_at'
    
    @players = Player.all

    timeframe
    query
    sort
    paginate
  end
  
  def show
    @player = Player.find(params[:id])
  end

  def destroy
    super Player, 'player', params[:id], admin_players_url, 'remove_player_row'
  end
private
  def timeframe
    @players = @players.where('players.last_login_at BETWEEN ? AND ?', Time.now.beginning_of_day, Time.now.end_of_day) if @filter == 'only_today'
    @players = Server.players if @filter == 'only_logged_in'
  end
  
  def query
    if @query.present?
      @players = @players.query(@query)
    end
  end
  
  def sort
    case @sort_field
    when 'links_count'
      @players = @players.select("players.*, ( SELECT COUNT(*) FROM links WHERE players.id = links.actor_id AND links.actor_type = 'Player') AS links_count").
        order("#{@sort_field} #{@sort_order}")
    else
      @players = @players.order("#{@sort_field} #{@sort_order}")
    end
  end
  
  def paginate
    @players = @players.paginate(page: params[:page], per_page: 100)
  end
end
