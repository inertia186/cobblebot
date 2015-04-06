module Admin::PlayersHelper
  def last_login(last_login_at)
    "#{distance_of_time_in_words_to_now(last_login_at)} ago" if !!last_login_at
  end
  
  def player_last_chat(player)
    return if player.last_chat.nil?
    
    content_tag(:code, id: "player_last_chat_#{player.id}") do
      player.last_chat
    end
    
  end
  
  def link_delete_player(player, options = {class: 'btn btn-danger'})
    link_to 'Delete', admin_player_path(player), class: options[:class], data: { confirm: 'Are you sure?  Deleting a player record only deletes the database row for that player.  If they log in again, a new row will then be created.', remote: true, method: :delete }
  end
end