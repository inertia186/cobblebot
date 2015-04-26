class Admin::IpsController < Admin::AdminController
  before_filter :http_authenticate_feed, only: :index
  before_filter :authenticate_admin!
  before_filter :setup_params, only: :index
  
  def index
    @player_id = params[:player_id]
    @player = Player.find @player_id if @player_id.present?
    @origin = params[:origin]
    
    if !!@player
      @ips = @player.ips
    else
      @ips = Ip.all
    end

    @ips = @ips.where(origin: @origin) if !!@origin

    timeframe
    query
    sort
    paginate
  end
private
  def timeframe
    @ips = @ips.where('ips.created_at BETWEEN ? AND ?', Time.now.beginning_of_day, Time.now.end_of_day) if @filter == 'only_today'
  end
  
  def query
    if @query.present?
      q = "%#{@query}%"
      @ips = @ips.query(q)
    end
  end
  
  def sort
    @ips = @ips.order("#{@sort_field} #{@sort_order}")
  end
  
  def paginate
    @ips = @ips.paginate(page: params[:page], per_page: 25)
  end
end
