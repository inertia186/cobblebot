class PlayersController < ApplicationController
  def index
    @players = Server.players.with_pvp_counts

    if params[:after].present?
      @after = params[:after] || Time.now.to_i
      head 204 and return if @after == 'undefined'
      
      after = Time.at(@after.to_i + 1)
      
      if Player.activity_after(after).any?
        # Player logged out, so we should allow one update to the page.
        @new_chat = []
      else
        p = @players.except(:select)
      
        head 204 and return if p.activity_after(after).none?

        @new_chat = p.last_chat_after(after).
          order('updated_at DESC').map do |p|
            {p.nick => p.last_chat}
          end.reverse
        
        head 204 if @new_chat.empty? && p.activity_after(after).none?
      end
    end

    @players_today = Player.with_pvp_counts.logged_in_today.where.not(id: @players.except(:select))
  end
end
