#= require jquery
#= require jquery_ujs
#= require turbolinks
#= require bootstrap.min
#= require chosen-jquery
#= require_tree .

document.updatePublicPlayersTimerId = -1
document.updateIrcCountTimerId = -1

updatePublicPlayers = ->
  after = $('#last_chat').attr 'data-last-chat-at'
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
      chat.slideToggle 'slow'
      return
    $('body').on 'click', '#chat_size', (e) ->
      chat = $('#chat')
      this.innerText = if this.innerText == '+' then '-' else '+' 
      chat.toggleClass('chat_full_screen')
      return
  return

$ ->
  if !!$('a#irc-link')
    document.updateIrcCountTimerId = setTimeout updateIrcCount, 60000
  return
