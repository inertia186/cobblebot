$("#public-players").replaceWith("<div id=\"public-players\"><%= raw escape_javascript(render('public_players')) %></div>")

<%
@new_chat.each do |chat|
  nick = chat.keys.first
  no_tags_text = chat.values.first.to_s
  text = no_tags_text %>
e = $("#player_nick_<%= raw escape_javascript(nick) %>")
no_tags_text = '<%= raw escape_javascript(no_tags_text) %>'
after = '<%= raw escape_javascript(@after.to_s) %>'
nick = '<%= raw escape_javascript(nick) %>'
text = '<%= raw escape_javascript(text) %>'
e.attr('data-title', no_tags_text)
document.chat.appendText(nick, text)

<% end %>
