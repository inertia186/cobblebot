#= require jquery
#= require jquery_ujs
#= require angular
#= require angular-resource
#= require turbolinks
#= require bootstrap.min
#= require chosen-jquery
#= require moment
#= require_tree .

document.updatePublicPlayersTimerId = -1
document.updateIrcCountTimerId = -1

if document.app == undefined
  document.app = angular.module("CobbleBot", ["ngResource"])

document.app.
config(["$httpProvider", ($httpProvider) ->
  # This deals with ActionController::InvalidAuthenticityToken:
  $httpProvider.defaults.headers.common['X-CSRF-Token'] = $('meta[name=csrf-token]').attr('content')
]).
factory("resourceCache", ["$cacheFactory", ($cacheFactory) ->
  $cacheFactory("resourceCache")
]).
directive("preloadResource", ["resourceCache", (resourceCache) ->
  link: (scope, element, attrs) ->
    resourceCache.put(attrs.preloadResource, attrs.data)
])

# Angular directives

document.app.
directive('chosen', ->
  restrict: 'A'
  link: (scope, element, attrs) ->
    return if attrs.chosen == 'false'
    $(element.context).chosen
      search_contains: true
      disable_search_threshold: 10
      no_results_text: 'Oops, nothing found!'
).
directive('selectPlayer', ['$http', ($http) ->
  restrict: 'A'
  link: (scope, element, attrs) ->
    return if attrs.selectPlayer == 'false'
    e = $(element.context)
    id = e.val()
    e.empty()
    e.append($('<option></option>'))

    $http.get(attrs.selectPlayer).success (data) ->
      angular.forEach data, (player, index) ->
        nick = player.nick
        nick += ' (aka: ' + player.last_nick + ')' if !!player.last_nick
        option = $('<option></option>').attr('value', player.id).text(nick)
        option.prop 'selected', switch (typeof id)
          when 'string' then parseInt(id) == player.id
          else ~id.indexOf(player.id.toString()) if !!id
        e.append(option)
      e.chosen("destroy").chosen() if attrs.chosen == 'true'
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
    $scope.counter = $scope.countFrom || 0
    if $element.html().trim().length == 0
      $element.append($compile('<span>{{counter}}</span>')($scope))
    else
      $element.append($compile($element.contents())($scope));
    timeloop = ->
      tick = ->
        $scope.$digest()
        if $scope.counter < $scope.countTo
          $scope.counter++
          timeloop()
      $timeout tick, $scope.interval

    timeloop()
  ]
])

# Angular Resources

document.app.
factory('Donation', ['$resource', 'resourceCache', ($resource, resourceCache) ->
  Donation = $resource "/donations/:id.json",
  {id: "@id"},
  {query: {cache: resourceCache, isArray: true}}
  angular.extend Donation.prototype,
    createdAgo: -> moment(@created_at).fromNow()

  Donation
]).
factory('Preference', ['$resource', 'resourceCache', ($resource, resourceCache) ->
  Preference = $resource "/admin/preferences/:key.json",
    {key: "@key"},
      query:
        cache: resourceCache, isArray: true
      # Note, standards compliance requires PUT, not PATCH, until RFC5789 is widely adopted.
      update: {method: "PUT"}

  MAX = 80
  ELLIPSIS = ' ...'

  angular.extend Preference.prototype,
    isJson: -> /_json$/.test @key
    isTimestamp: -> /_timestamp$/.test @key
    isVerbose: ->
      !!@value &&
      ( @value.length >= MAX + ELLIPSIS.length ||
      @value.indexOf("\n") != -1 || @isJson() )
    isTruthy: -> /_enabled$|latest_gametick_in_progress/.test @key
    isSecure: -> /password|_key$|_salt$/.test @key
    isCommandScheme: -> /command_scheme/.test @key
    isSlackGroup: -> /slack_group/.test @key
    isTextField: ->
      !@isSlackGroup() && !@isCommandScheme() && !@isTruthy() && !@isVerbose()
    displayKey: ->
      switch(@key)
        when 'web_admin_password' then 'Web Admin Password'
        when 'path_to_server' then 'Path to Server'
        when 'command_scheme' then 'Command Scheme'
        when 'motd' then 'MOTD'
        when 'irc_enabled' then 'IRC Enabled'
        when 'irc_info' then 'IRC Info'
        when 'irc_web_chat_enabled' then 'IRC Web Chat Enabled'
        when 'irc_web_chat_url_label' then 'IRC Web Chat URL Label'
        when 'irc_web_chat_url' then 'IRC Web Chat URL'
        when 'irc_server_host' then 'IRC Server Host'
        when 'irc_server_port' then 'IRC Server Port'
        when 'irc_nick' then 'IRC Nick'
        when 'irc_channel' then 'IRC Channel'
        when 'irc_channel_ops' then 'IRC Channel OPs'
        when 'irc_nickserv_password' then 'IRC NICKSERV Password'
        when 'rules_json' then 'Rules JSON'
        when 'tutorial_json' then 'Tutorial JSON'
        when 'origin_salt' then 'Origin Salt'
        when 'db_ip_api_key' then 'DBIP API Key'
        when 'faq_json' then 'FAQ JSON'
        when 'donations_json' then 'Donations JSON'
        when 'mmp_api_key' then 'minecraft-mp.com API Key'
        when 'slack_api_key' then 'Slack API Key'
        when 'slack_group' then 'Slack Group'
        else @key
    displayValue: ->
      if @isSecure()
        '********'
      else if @isTruthy()
        @value == '1' || @value == 't'
      else if @isTimestamp()
        new Date(@value * 1000)
      else
        if @isVerbose() then @value.substring(0, MAX) + ELLIPSIS else @value
    errors: ->
      if !@key && !!@value
        @value

  Preference
]).
factory('Pvp', ['$resource', 'resourceCache', ($resource, resourceCache) ->
  Pvp = $resource "/pvps/:id.json",
  {id: "@id"},
  {query: {cache: resourceCache, isArray: true}}
  angular.extend Pvp.prototype,
    createdAgo: -> moment(@created_at).fromNow()

  Pvp
]).
factory('Stat', ['$resource', 'resourceCache', ($resource, resourceCache) ->
  Stat = $resource "/status/:key.json?angular.version=" + angular.version.codeName + " (" + angular.version.full + ")",
  {key: "@key"},
  {query: {cache: resourceCache, isArray: true}}
  angular.extend Stat.prototype,
    isTimestamp: -> /timestamp/.test @key
    displayKey: ->
      switch(@key)
        when 'gametype' then 'Game Type'
        when 'game_id' then 'Game ID'
        when 'version' then 'Version'
        when 'plugins' then 'Plugins'
        when 'map' then 'Map'
        when 'numplayers' then 'No. of Players'
        when 'maxplayers' then 'Max No. of Players'
        when 'hostip' then 'Host IP'
        when 'motd' then 'Message of the Day'
        when 'rawplugins' then 'Raw Plugins'
        when 'server' then 'Server'
        when 'timestamp' then 'Timestamp'
        else @key
    displayValue: ->
      if @isTimestamp()
        new Date(@value * 1000)
      else if @value == null
        'N/A'
      else if @value.length == 0
        "None"
      else
        @value

  Stat
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
