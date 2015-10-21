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
  $.getScript('/players.js?after=' + after).done ->
    document.updatePublicPlayersTimerId = setTimeout updatePublicPlayers, 5000

updateIrcCount = ->
  $.getScript('/irc.js').done ->
    document.updateIrcCountTimerId = setTimeout updateIrcCount, 60000

$ ->
  if $('#public-players').length > 0
    document.updatePublicPlayersTimerId = setTimeout updatePublicPlayers, 5000
    document.chat = chat = $.extend $('#chat'),
      toggleChat: ->
        if @hasClass 'chat_bottom_only' || @hasClass 'chat_full_screen'
          @hideText()
        else
          @miniText()
      toggleSize: ->
        if @hasClass 'chat_bottom_only'
          @fullText()
        else
          @miniText()
      hideText: ->
        $('#chat_size')[0].innerText = '-'
        @toggleClass('chat_hidden', 250).promise().done ->
          @removeClass 'chat_bottom_only'
          @removeClass 'chat_full_screen'
          @scrollToBottom()
      fullText: ->
        $('#chat_size')[0].innerText = '-'
        @toggleClass('chat_full_screen', 250).promise().done ->
          @removeClass 'chat_bottom_only'
          @scrollToBottom()
      miniText: ->
        $('#chat_size')[0].innerText = '+'
        @toggleClass('chat_bottom_only', 250).promise().done ->
          @removeClass 'chat_hidden'
          @removeClass 'chat_full_screen'
          @scrollToBottom()
      appendText: (nick, toAppend) ->
        if @text().indexOf toAppend == -1
          @append "&lt;" + nick + "&gt; " + toAppend + "<br />"
        if @hasClass 'chat_hidden'
          @miniText()
        else
          @scrollToBottom
      scrollToBottom: ->
        @animate {scrollTop: @offset().top}, 2500

    $('body').on 'click', '#chat_controls', (e) -> chat.toggleChat()
    $('body').on 'click', '#chat_size', (e) -> chat.toggleSize()

$ ->
  if !!$('a#irc-link')
    document.updateIrcCountTimerId = setTimeout updateIrcCount, 60000
