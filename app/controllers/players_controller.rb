class PlayersController < ApplicationController
  def index
    @players = Server.players.with_pvp_counts

    if params[:after].present?
      head 204 and return if params[:after] == 'undefined'
      
      after = Time.at(params[:after].to_i + 1)
      p = @players.except(:select)
      
      @new_chat = p.last_chat_after(after).
        order('updated_at DESC').map do |p|
          {p.nick => p.last_chat}
        end.reverse
        
      head 204 if p.activity_after(after).none? && @new_chat.empty?
    end

    @players_today = Player.with_pvp_counts.logged_in_today.where.not(id: @players.except(:select))
  end
end
