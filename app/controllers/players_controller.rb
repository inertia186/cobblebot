class PlayersController < ApplicationController
  def index
    @players = Server.players.with_pvp_counts
    @players_today = Player.with_pvp_counts.logged_in_today.where.not(id: @players.except(:select))
    
    if params[:after].present?
      after = Time.at(params[:after].to_i + 1)
      
      @new_chat = @players.except(:select).last_chat_after(after).
        order('updated_at DESC').map do |p|
          {p.nick => p.last_chat}
        end.reverse
      head 204 if @new_chat.empty? && @players.any?
    end
  end
end
