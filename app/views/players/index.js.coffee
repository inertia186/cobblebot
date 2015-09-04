$("#public-players").replaceWith("<div id=\"public-players\"><%= raw escape_javascript(render('public_players')) %></div>")

<% @new_chat.each do |chat| %>
e = $("#player_nick_<%= chat.keys.first %>")
e.attr('data-title', '<%= escape_javascript(chat.values.first) %>')
chat = $("#chat")
chat.slideDown('slow')
chat.append("&lt;<%= chat.keys.first %>&gt; <%= escape_javascript(chat.values.first) %><br />")
<% end %>