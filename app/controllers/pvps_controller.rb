class PvpsController < ApplicationController
  SORT_FIELDS = {
    'body' => 'messages.body',
    'created_at' => 'messages.created_at',
    'messages.created_at' => 'messages.created_at'
  }.freeze

  before_action :setup_params, only: :index
  respond_to :html, :json, :atom
  
  def index
    requested_sort = params[:sort_field].presence || 'messages.created_at'
    @sort_field = SORT_FIELDS.fetch(requested_sort, 'messages.created_at')
    
    @pvps = Message::Pvp.order("#{@sort_field} #{@sort_order}")
    @pvps = @pvps.preload(:recipient, :author)
    @pvps = @pvps.query(@query) if @query.present?
    
    respond_to do |format|
      format.html {
        #@pvps = @pvps.paginate(page: params[:page], per_page: 100)
      }
      format.json { respond_with @pvps }
      format.atom
    end
  end
end
