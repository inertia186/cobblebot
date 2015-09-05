class PlayersController < ApplicationController
  def index
    @players = Server.players
    @players_today = Player.logged_in_today.where.not(id: @players)
    
    if params[:after].present?
      after = Time.at(params[:after].to_i + 1)
      
      @new_chat = @players.last_chat_after(after).
        order('updated_at DESC').map do |p|
          {p.nick => p.last_chat}
        end.reverse
    end
  end
end
