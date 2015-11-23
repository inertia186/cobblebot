#= require jquery2
#= require jquery_ujs
#= require angular
#= require angular-resource
#= require turbolinks
#= require bootstrap
#= require chosen-jquery
#= require moment
#= require_tree .

document.updatePublicPlayersTimerId = -1
document.updateIrcCountTimerId = -1

if document.app == undefined
  document.app = angular.module("CobbleBot", ["ngResource"])

document.app.config(["$httpProvider", ($httpProvider) ->
  # This deals with ActionController::InvalidAuthenticityToken:
  $httpProvider.defaults.headers.common['X-CSRF-Token'] = $('meta[name=csrf-token]').attr('content')
]).
factory("resourceCache", ["$cacheFactory", ($cacheFactory) ->
  $cacheFactory("resourceCache")
]).
directive("preloadResource", ["resourceCache", (resourceCache) ->
  link: (scope, element, attrs) ->
    resourceCache.put(attrs.preloadResource, attrs.data)
]).
directive('flash', ['$compile', ($compile) ->
  restrict: 'E'
  scope:
    messages: '=messages'
  controller: ['$scope', '$element', '$attrs', ($scope, $element, $attrs) ->
    angular.forEach $scope.messages, (f) ->
      $scope.message = f[1]
      $scope.alertType = switch f[0]
        when 'notice' then 'success'
        when 'info' then 'info'
        when 'alert' then 'warning'
        when 'error' then 'danger'
        else f[0]
      template = '''
        <strong role="alert" class="center-block alert alert-{{alertType}}">
          {{message}}
        </strong>
      '''
      $element.append $compile(template)($scope)
  ]
]).
directive('suggestion', -> {
  restrict: 'E',
  templateUrl: (e, attr) ->
    module = if attr.module == undefined
      ''
    else
      '/' + attr.module
      
    verbose = if attr.verbose == undefined
      true
    else
      attr.verbose == 'true'
      
    module + '/suggestion/' + attr.group + '/' + attr.key + "?verbose=" + verbose
}).
directive('repeatComplete', ['$rootScope', ($rootScope) ->
  uuid = 0
  {
    compile: (element, attr) ->
      id = ++uuid
      element.attr("repeat-complete-id", id)
      element.removeAttr("repeat-complete")
    
      completeExpression = attr.repeatComplete
      parent = element.parent()
      parentScope = (parent.scope() || $rootScope)
      unbindWatcher = parentScope.$watch ->
        lastItem = parent.children("*[ repeat-complete-id = '" + id + "' ]:last")
        return if !lastItem.length
      
        itemScope = lastItem.scope()
      
        if itemScope.$last
          unbindWatcher();
          itemScope.$eval(completeExpression);
      
      true
    priority: 1001,
    restrict: "A"
  }
]).
directive('countUp', ['$compile', '$timeout', ($compile, $timeout) ->
  priority: -9001
  restrict: 'E'
  replace: false
  scope:
    countFrom: '@countFrom'
    countTo: '@countTo'
    interval: '=interval'
  controller: ['$scope', '$element', '$attrs', '$timeout', ($scope, $element, $attrs, $timeout) ->
    i = $scope.millis = $scope.countFrom || 0
    if $element.html().trim().length == 0
      $element.append($compile('<span>{{millis}}</span>')($scope))
    else
      $element.append($compile($element.contents())($scope));
      
    timeloop = ->
      tick = ->
        $scope.millis++
        $scope.$digest()
        i++
        timeloop() if i < $scope.countTo
      setTimeout tick, $scope.interval
    
    timeloop()
  ]
])

$(document).on 'ready page:load', -> angular.bootstrap 'body', ['CobbleBot']
  
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
        h = @html()
        if h.length > 2048
          tk = '&lt;'
          i = h.indexOf tk
          j = h.substring(i + tk.length).indexOf tk
          k = i + j + tk.length
          c = h.substring 0, i
          @html(c + h.substring k)

        if h.indexOf(toAppend) == -1
          @append "&lt;" + nick + "&gt; " + toAppend + "<br />"
        if @hasClass 'chat_hidden'
          @miniText()
        else
          @scrollToBottom()
      scrollToBottom: ->
        @animate {scrollTop: @offset().top}, 2500

    $('body').on 'click', '#chat_controls', (e) -> chat.toggleChat()
    $('body').on 'click', '#chat_size', (e) -> chat.toggleSize()

$ ->
  if !!$('a#irc-link')
    document.updateIrcCountTimerId = setTimeout updateIrcCount, 60000
