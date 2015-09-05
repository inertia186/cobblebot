#= require jquery
#= require jquery_ujs
#= require turbolinks
#= require bootstrap.min
#= require_tree .

updatePublicPlayers = ->
  after = $('#last_chat').attr('data-last-chat-at')
  $.getScript '/players.js?after=' + after
  setTimeout updatePublicPlayers, 5000
  return

$ ->
  if $('#public-players').length > 0
    setTimeout updatePublicPlayers, 5000
    $('body').on 'click', '#chat_controls', (e) ->
      chat = $('#chat')
      chat.slideToggle 'slow'
      return
  return
