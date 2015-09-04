$("#public-players").replaceWith("<div id=\"public-players\"><%= raw escape_javascript(render('public_players')) %></div>")

<% @new_chat.each do |chat| %>
e = $("#player_nick_<%= chat.keys.first %>")
new_chat = '<%= escape_javascript(chat.values.first) %>'
e.attr('data-title', new_chat)
chat = $("#chat")
chat.slideDown('slow')
if ( chat.text().indexOf(new_chat) == -1 )
  chat.append("&lt;<%= chat.keys.first %>&gt; " + new_chat + "<br />")
  chat.scrollTop(chat.height())
<% end %>