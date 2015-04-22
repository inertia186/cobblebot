class Api::V1::PlayersController < Api::V1::ApiController
  def index
    only_registered = params[:only_registered]
    any_nick = params[:any_nick]
    @players = Player.all
    
    @players = @players.registered if !!only_registered
    @players = @players.any_nick(any_nick) if !!any_nick
  end
  
  def show
    @player = Player.find(params[:id])
  end
end