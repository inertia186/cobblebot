class Admin::DonationsController < Admin::AdminController
  before_filter :http_authenticate_feed, only: :index
  before_filter :authenticate_admin!
  before_filter :setup_params, only: :index
  
  def index
    @author_id = params[:author_id]
    @author_type = params[:author_type] || 'Player'

    if params[:player_id].present?
      @author_id = params[:player_id]
      @author_type = 'Player'
    end

    @donations = Message::Donation.all

    if @author_id.present? && @author_type == 'Player'
      @author = Player.find @author_id
      @donations = @donations.where(author_id: @author_id)
    end
      
    timeframe
    query
    sort
    paginate
  end

  def show
    @donation = Message::Donation.find(params[:id])
  end
  
  def new
    @donation = Message::Donation.new
  end
  
  def edit
    @donation = Message::Donation.find(params[:id])
  end
  
  def create
    donation_params[:author_type] ||= 'Player' unless donation_params[:author_id].nil?
    
    @donation = Message::Donation.new(donation_params)

    if @donation.save
      redirect_to admin_message_donations_url
    else
      render action: 'new'
    end
  end
  
  def update
    donation_params[:author_type] ||= 'Player' unless donation_params[:author_id].nil?

    @donation = Message::Donation.find(params[:id])

    if @donation.update_attributes(donation_params)
      redirect_to admin_message_donations_url
    else
      render action: 'edit'
    end
  end
  
  def destroy
    super Message::Donation, 'donation', params[:id], admin_message_donations_url, 'remove_donation_row'
  end
private
  def timeframe
    @donations = @donations.where('messages.created_at BETWEEN ? AND ?', Time.now.beginning_of_day, Time.now.end_of_day) if @filter == 'only_today'
  end

  def query
    if @query.present?
      q = "%#{@query}%"
      @donations = @donations.query(q)
    end
  end

  def sort
    case @sort_field
    when 'donation_author_nick'
      @donations = @donations.select("messages.*, lower(authors.nick) AS donation_author_nick").
        joins("LEFT OUTER JOIN players AS authors ON ( messages.author_type = 'Player' AND messages.author_id = authors.id )").
        order("#{@sort_field} #{@sort_order}")
    else
      @donations = @donations.order("#{@sort_field} #{@sort_order}")
    end
  end

  def paginate
    @donations = @donations.paginate(page: params[:page], per_page: params[:per_page] || 25)
  end

  def donation_params
    attributes = [:author_id, :author_type, :body]

    params.require(:message_donation).permit *attributes
  end
end
