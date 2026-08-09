class Api::V1::PlayersController < Api::V1::ApiController
  def index
    only_registered = ActiveModel::Type::Boolean.new.cast(params[:only_registered])
    any_nick = params[:any_nick]
    origin = params[:origin]
    cc = params[:cc]

    @players = Player.all
    
    @players = @players.registered if only_registered
    @players = @players.any_nick(any_nick) if any_nick.present?
    @players = @players.where(id: Ip.where(origin: origin).select(:player_id)) if origin.present?
    @players = @players.where(id: Ip.where(cc: cc).select(:player_id)) if cc.present?
  end
  
  def show
    @player = Player.find(params[:id])
  end
end
