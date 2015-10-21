$("#public-players").replaceWith("<div id=\"public-players\"><%= raw escape_javascript(render('public_players')) %></div>")

<%
@new_chat.each do |chat|
  nick = chat.keys.first
  no_tags_text = text = chat.values.first
  text.gsub!(/(http[^ ]+)/, link_to("\\1", "\\1", target: '_new').html_safe) %>
e = $("#player_nick_<%= nick %>")
no_tags_text = '<%= raw escape_javascript(no_tags_text) %>'
after = '<%= @after %>'
nick = '<%= nick %>'
text = '<%= raw escape_javascript(text) %>'
e.attr('data-title', no_tags_text)
document.chat.appendText(nick, text)

<% end %>