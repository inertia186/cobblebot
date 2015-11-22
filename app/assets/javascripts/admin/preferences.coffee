if document.app == undefined
  document.app = angular.module("CobbleBot", ["ngResource"])

document.app.
  factory('Preference', ['$resource', '$rootScope', ($resource, $rootScope) ->
    Preference = $resource "/admin/preferences/:key.json", {
      key: "@key"
    }, {
      update: {
        method: "PATCH",
        interceptor: {
          response: (response) ->
            key = response['config']['data']['key']
            $rootScope.errorMessage = ''
            $rootScope.errorMode = false
            $rootScope.$broadcast 'rootScope:ok', {key: key}
          responseError: (response) ->
            key = response['config']['data']['key']
            message = response['data']['value'][0]
            $rootScope.errorMessage = message
            $rootScope.errorMode = true
            $rootScope.$broadcast 'rootScope:error', {key: key, message: message}
        }
      }
    }
    decoratePreferenceType angular, Preference

    Preference
  ]).factory("PreloadedPreference", ['$resource', '$cacheFactory', '$window', 'Preference', ($resource, $cacheFactory, $window, Preference) ->
    cached = $window.preloadedPreferences
    angular.forEach cached, (item, key) ->
      cached[key] = new Preference(key: key, value: item)

    $cacheFactory.get('$http').put '/admin/preferences.json', cached

    PreloadedPreference = $resource "/admin/preferences/:key.json",
      {key: "@key"},
      {query: {cache: true}}
    decoratePreferenceType angular, PreloadedPreference

    PreloadedPreference
  ]).
  controller('PreferenceCtrl', ['$scope', 'Preference', 'PreloadedPreference', ($scope, Preference, PreloadedPreference) ->
    $scope.preferences = PreloadedPreference.query()

    $scope.edit = (preference) ->
      preference.original_value = preference.value
      $scope.checkStrength(preference) if preference.isSecure()
    $scope.save = (preference) -> Preference.update(preference)
    $scope.cancel = (preference) -> preference.value = preference.original_value
    $scope.checkStrength = (preference) ->
      if preference.value.length >= 8
        $scope.strength = 'strong';
      else if preference.value.length >= 6
        $scope.strength = 'medium'
      else
        $scope.strength = 'weak'

    $scope.$on 'rootScope:ok', (event, data) ->
      key = data['key']
      
      angular.forEach $scope.preferences, (preference) ->
        if preference.key == key
          table_row = $("tr#" + key)
          error_message = $("#" + key + " * .error_message")
          table_row.removeClass("alert alert-danger")
          error_message.removeClass("alert alert-danger")
          error_message.empty()

    $scope.$on 'rootScope:error', (event, data) ->
      key = data['key']
      message = data['message']
      
      angular.forEach $scope.preferences, (preference) ->
        if preference.key == key
          table_row = $("tr#" + key)
          error_message = $("#" + key + " * .error_message")
          table_row.addClass("alert alert-danger")
          error_message.addClass("alert alert-danger")
          error_message.append(message)
  ]).
  directive('editCell', -> {
    controller: 'PreferenceCtrl',
    restrict: 'E',
    templateUrl: 'preferences/edit_cell'
  }).
  directive('slackGroupElement', -> {
    controller: 'PreferenceCtrl',
    restrict: 'E',
    templateUrl: 'preferences/slack_group_element'
  })

decoratePreferenceType = (angular, type) ->
  MAX = 80
  ELLIPSIS = ' ...'

  angular.extend type.prototype,
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
