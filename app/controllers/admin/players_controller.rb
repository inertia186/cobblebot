require 'digest/md5'

class Admin::PlayersController < Admin::AdminController
  before_filter :authenticate_admin!
  before_filter :setup_params, only: :index
  
  def index
    @sort_field = params[:sort_field].present? ? params[:sort_field] : 'last_login_at'
    @origin = params[:origin]
    @cc = params[:cc]
    
    @players = Player.all

    @players = @players.where(id: Ip.where(origin: @origin).select(:player_id)) if !!@origin
    @players = @players.where(id: Ip.where(cc: @cc).select(:player_id)) if !!@cc

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

  def toggle_may_autolink
    @player = Player.find(params[:id])
    
    if @player.update_attribute(:may_autolink, !@player.may_autolink?)
      respond_to do |format|
        format.html { redirect_to return_to }
        format.js { render 'show' }
      end
    end
  end
private
  def timeframe
    @players = @players.where.not(registered_at: nil) if @filter == 'only_registered'
    @players = @players.where('players.last_login_at BETWEEN ? AND ?', Time.now.beginning_of_day, Time.now.end_of_day) if @filter == 'only_today'
    @players = @players.newly_created if @filter == 'only_new'
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
    when 'messages_count'
      @players = @players.select("players.*, ( SELECT COUNT(*) FROM messages WHERE players.id = messages.recipient_id AND messages.recipient_type = 'Player') AS messages_count").
        order("#{@sort_field} #{@sort_order}")
    when 'latest_country_code'
      @players = @players.select("players.*, ( SELECT ips.cc FROM ips WHERE players.id = ips.player_id ORDER BY ips.id DESC LIMIT 1 ) AS latest_country_code").
        order("#{@sort_field} #{@sort_order}")
    else
      @players = @players.order("#{@sort_field} #{@sort_order}")
    end
  end
  
  def paginate
    @players = @players.paginate(page: params[:page], per_page: 100)
  end
end
