class PvpsController < ApplicationController
  def index
    @pvps = Message::Pvp.order('messages.created_at DESC')
    @pvps = @pvps.paginate(page: params[:page], per_page: 100)
  end
end
