e = $('a#irc-link')
c = <%= @active_in_irc %>
new_text = "IRC"
old_text = e.text()

if c > 0
  new_text = "IRC (" + c + ")"

if old_text != new_text
  e.toggle('highlight')
  e.text(new_text)
  e.toggle('highlight')
