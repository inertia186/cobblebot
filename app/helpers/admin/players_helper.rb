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
  
  def link_remote_toggle_autolink(player, options = {class: 'btn btn-warning', confirm: 'Are you sure?'})
    title = if player.may_autolink?
      'Disable Auto-link'
    else
      'Enable Auto-link'
    end
    
    link_to title, toggle_may_autolink_admin_player_path(player), class: options[:class], data: { confirm: options[:confirm], remote: true, method: :patch }
  end
end