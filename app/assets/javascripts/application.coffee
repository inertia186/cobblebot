#= require jquery2
#= require jquery_ujs
#= require tether
#= require bootstrap
#= require angular
#= require angular-inview
#= require angular-animate
#= require angular-resource
#= require angular-flash-alert
#= require angular-ui-bootstrap
#= require angular-ui-bootstrap-tpls
# require angular-cancel-on-navigate # Including angularCancelOnNavigateModule.js instead because the package has issues.
#= require moment
#= require chosen
#= require ngclipboard
#= require clipboard
#= require nprogress
#= require main
#= require_tree .

document.updatePublicPlayersTimerId = -1
document.updateIrcCountTimerId = -1

updatePublicPlayers = ->
  after = $('#last_activity').attr 'data-last-activity-at'
  $.getScript('/players.js?after=' + after).done ->
    document.updatePublicPlayersTimerId = setTimeout updatePublicPlayers, 5000

updateIrcCount = ->
  unless $('a#irc-link').length > 0
    clearTimeout document.updateIrcCountTimerId
    document.updateIrcCountTimerId = -1
    return

  $.getScript('/irc.js').done ->
    if $('a#irc-link').length > 0
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
        h = @html()
        if h.length > 2048
          tk = '&lt;'
          i = h.indexOf tk
          j = h.substring(i + tk.length).indexOf tk
          k = i + j + tk.length
          c = h.substring 0, i
          @html(c + h.substring k)

        if h.indexOf(toAppend) == -1
          line = $('<span>')
          line.append document.createTextNode("<#{nick}> ")

          source = String(toAppend)
          urlPattern = /\bhttps?:\/\/[^\s<>"']+/g
          position = 0
          while match = urlPattern.exec(source)
            line.append document.createTextNode(source.substring(position, match.index))
            $('<a>',
              href: match[0]
              target: '_blank'
              rel: 'noopener noreferrer'
            ).text(match[0]).appendTo(line)
            position = urlPattern.lastIndex
          line.append document.createTextNode(source.substring(position))

          @append(line).append $('<br>')
        if @hasClass 'chat_hidden'
          @miniText()
        else
          @scrollToBottom()
      scrollToBottom: ->
        @animate {scrollTop: @offset().top}, 2500

    $('body').on 'click', '#chat_controls', (e) -> chat.toggleChat()
    $('body').on 'click', '#chat_size', (e) -> chat.toggleSize()
    
  if $('a#irc-link').length > 0
    document.updateIrcCountTimerId = setTimeout updateIrcCount, 60000

  NProgress.configure
    showSpinner: true,
    ease: 'ease',
    speed: 100,
    minimum: 0.08

  $(document).on 'ajaxStart page:fetch', -> NProgress.start()
  $(document).on 'submit', 'form', -> NProgress.start()
  $(document).on 'ajaxStop page:change', -> NProgress.done()
  $(document).on 'page:receive', -> NProgress.set(0.7)
  $(document).on 'page:restore', -> NProgress.remove()
    
  $(document).on 'page:change', ->
    if !!(fieldset = $('fieldset:has(.field_with_errors)'))
      fieldset.addClass('has-danger') 
    if !!(any = $('.field_with_errors'))
      any.addClass('has-danger') 
    if !!(input = $('.field_with_errors > input'))
      input.addClass('form-control-danger') 
    if !!(label = $('.field_with_errors > label'))
      label.addClass('control-danger') 
