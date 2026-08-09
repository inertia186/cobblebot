class PlayersController < ApplicationController
  MAX_POLLING_TIMESTAMP = Time.utc(9999, 12, 31, 23, 59, 59).to_i

  skip_before_action :check_server_status, if: :asynchronous_request

  def index
    @players = Server.players.with_pvp_counts

    if params[:after].present?
      head 204 and return unless Server.up?
      @after = params[:after] || Time.now.to_i
      head 204 and return if @after == 'undefined'
      
      after = polling_time(@after)
      head 204 and return unless after

      head 204 and return if Server.latest_log_entry_at.nil? || Server.latest_log_entry_at < after
      
      if Player.activity_after(after).last_chat_before(after).any?
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
private
  def polling_time(value)
    timestamp = Integer(value, 10)
    return unless timestamp.between?(0, MAX_POLLING_TIMESTAMP)

    Time.at(timestamp + 1)
  rescue ArgumentError, RangeError
    nil
  end

  def asynchronous_request
    params[:format] == 'js'
  end
end
