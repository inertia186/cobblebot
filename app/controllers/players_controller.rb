class PlayersController < ApplicationController
  def index
    @players = Server.players
    @players_today = Player.logged_in_today.where.not(id: @players)
  end
end
