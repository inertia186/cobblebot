$("#public-players").replaceWith("<div id=\"public-players\"><%= raw escape_javascript(render('public_players')) %></div>")

<%
@new_chat.each do |chat|
  nick = chat.keys.first
  no_tags_text = text = chat.values.first
  text.gsub!(/(http[^ ]+)/, link_to("\\1", "\\1", target: '_new').html_safe) %>
e = $("#player_nick_<%= nick %>")
no_tags_text = '<%= raw escape_javascript(no_tags_text) %>'
text = '<%= raw escape_javascript(text) %>'
e.attr('data-title', no_tags_text)
chat = $('#chat')

if chat.text().indexOf(text) == -1
  chat.append("&lt;<%= nick %>&gt; " + text + "<br />")

if chat.hasClass('chat_hidden')
  chat_size.innerText = '+'
  chat.toggleClass('chat_bottom_only', 250).promise().done ->
    chat.removeClass('chat_hidden')
    chat.animate({scrollTop: chat.offset().top}, 'slow')
else
  chat.animate({scrollTop: chat.offset().top}, 'slow')

<% end %>