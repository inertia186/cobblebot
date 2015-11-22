class PvpsController < ApplicationController
  before_filter :setup_params, only: :index
  respond_to :json
  
  def index
    @sort_field = params[:sort_field].present? ? params[:sort_field] : 'messages.created_at'
    
    @pvps = Message::Pvp.order("#{@sort_field} #{@sort_order}")
    @pvps = @pvps.preload(:recipient, :author)
    @pvps = @pvps.query(@query) if @query.present?
    
    respond_to do |format|
      format.html {
        #@pvps = @pvps.paginate(page: params[:page], per_page: 100)
      }
      format.json { respond_with @pvps }
    end
  end
end
