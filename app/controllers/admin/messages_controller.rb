class Admin::MessagesController < Admin::AdminController
  before_filter :http_authenticate_feed, only: :index
  before_filter :authenticate_admin!
  before_filter :setup_params, only: :index
  
  def index
    cache_key = request.env["HTTP_IF_NONE_MATCH"]
    
    @author_id = params[:author_id]
    @author_type = params[:author_type] || 'Player'

    if params[:player_id].present?
      @recipient_id = params[:player_id]
      @recipient_type = 'Player'
    else
      @recipient_id = params[:recipient_id]
      @recipient_type = params[:recipient_type] || 'Player'
    end

    @messages = Message.where(type: nil)
    unless params[:filter_modes] == 'false'
      @messages = @messages.read(params[:read] == 'true')
      @messages = @messages.deleted(params[:deleted] == 'true')
      @messages = @messages.muted(params[:muted] == 'true')
    end
    if @author_id.present? && @author_type == 'Player'
      @recipient = Player.where(id: @author_id)
      @messages = @messages.where(recipient_type: @author_type, author_id: @author_id)
    end
      
    if @recipient_id.present? && @recipient_type == 'Player'
      @recipient = Player.where(id: @recipient_id)
      @messages = @messages.where(recipient_type: @recipient_type, recipient_id: @recipient_id)
    end

    @recipient ||= []
    @messages = @messages.preload(:author, :recipient)

    timeframe
    query
    sort
    paginate
    
    head 304 and return if cache_key == etag
    
    response.headers['ETag'] = etag
  end

  def show
    @message = Message.find(params[:id])
  end
private
  def timeframe
    @messages = @messages.where('messages.created_at BETWEEN ? AND ?', Time.now.beginning_of_day, Time.now.end_of_day) if @filter == 'only_today'
  end

  def query
    if @query.present?
      q = "%#{@query}%"
      @messages = @messages.query(q)
    end
  end

  def sort
    case @sort_field
    when 'message_author_nick'
      @messages = @messages.select("messages.*, lower(authors.nick) AS message_author_nick").
        joins("LEFT OUTER JOIN players AS authors ON ( messages.author_type = 'Player' AND messages.author_id = authors.id )").
        order("#{@sort_field} #{@sort_order}")
    when 'message_recipient_nick'
      @messages = @messages.select("messages.*, lower(recipients.nick) AS message_recipient_nick").
        joins("LEFT OUTER JOIN players AS recipients ON ( messages.recipient_type = 'Player' AND messages.recipient_id = recipients.id )").
        order("#{@sort_field} #{@sort_order}")
    when 'muted_at'
      @messages = @messages.select("messages.*, ( SELECT mutes.created_at FROM mutes WHERE mutes.player_id = recipient_id AND mutes.muted_player_id = author_id ) AS muted_at").
        order("#{@sort_field} #{@sort_order}")
    else
      @messages = @messages.order("#{@sort_field} #{@sort_order}")
    end
  end

  def paginate
    @messages = @messages.paginate(page: params[:page], per_page: params[:per_page] || 25)
  end
  
  def etag
    Digest::MD5.hexdigest @messages.except(:order).pluck(:id).to_s
  end
end