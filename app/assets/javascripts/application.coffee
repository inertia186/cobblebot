#= require jquery
#= require jquery_ujs
#= require turbolinks
#= require bootstrap.min
#= require chosen-jquery
#= require_tree .

document.updatePublicPlayersTimerId = -1
document.updateIrcCountTimerId = -1

updatePublicPlayers = ->
  after = $('#last_activity').attr 'data-last-activity-at'
  $.getScript '/players.js?after=' + after
  document.updatePublicPlayersTimerId = setTimeout updatePublicPlayers, 5000
  return

updateIrcCount = ->
  $.getScript '/irc.js'
  document.updateIrcCountTimerId = setTimeout updateIrcCount, 60000
  return

$ ->
  if $('#public-players').length > 0
    document.updatePublicPlayersTimerId = setTimeout updatePublicPlayers, 5000
    $('body').on 'click', '#chat_controls', (e) ->
      chat = $('#chat')
      chat_size = $('#chat_size')[0]
      
      if chat.hasClass('chat_full_screen')
        chat.toggleClass('chat_full_screen chat_hidden').promise().done ->
          chat_size.innerText = '-'
          chat.scrollTop(chat.height() * 100)
      else
        chat.toggleClass('chat_bottom_only chat_hidden').promise().done ->
          chat_size.innerText = '+'
          chat.scrollTop(chat.height() * 100)
          
      return
      
    $('body').on 'click', '#chat_size', (e) ->
      chat = $('#chat')
      chat_size = $('#chat_size')[0]

      chat.toggleClass('chat_full_screen chat_bottom_only').promise().done ->
        if chat_size.innerText == '+'
          chat_size.innerText = '-'
        else
          chat_size.innerText = '+'
        chat.scrollTop(chat.height() * 100)
        
      return
  return

$ ->
  if !!$('a#irc-link')
    document.updateIrcCountTimerId = setTimeout updateIrcCount, 60000
  return
