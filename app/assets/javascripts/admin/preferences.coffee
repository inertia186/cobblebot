document.app = angular.module("CobbleBot", ["ngResource"]).config(["$httpProvider", ($httpProvider) ->
    $httpProvider.defaults.headers.common['X-CSRF-Token'] = $('meta[name=csrf-token]').attr('content')
    $httpProvider.interceptors.push('LoadingInterceptor');
  ]).
  factory("Preference", ['$resource', ($resource) ->
    MAX = 80
    ELLIPSIS = ' ...'
    Preference = $resource "/admin/preferences/:key.json",
      {key: "@key"},
      {update: {method: "PATCH"}}
    angular.extend Preference.prototype,
      json: -> @key.indexOf('_json') != -1
      verbose: ->
        @value.length >= MAX + ELLIPSIS.length ||
        @value.indexOf("\n") != -1 ||
        @json()
      truthy: -> @key == 'irc_enabled' || @key == 'irc_web_chat_enabled'
      secure: ->
        @key.indexOf('password') != -1 ||
        @key.indexOf('_key') != -1 ||
        @key.indexOf('_salt') != -1
      command_scheme: -> @key == 'command_scheme'
      slack_group: -> @key == 'slack_group'
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
        if @secure()
          '********'
        else if @truthy()
          @value == '1'
        else
          if @verbose()
            @value.substring(0, MAX) + ELLIPSIS
          else
            @value
          
    Preference
  ]).
  controller('PreferenceCtrl', ['$scope', 'Preference', ($scope, Preference) ->
    $scope.preferences = Preference.query()
    $scope.edit = (preference) ->
      preference.original_value = preference.value
    $scope.save = (preference) -> Preference.update(preference)
    $scope.cancel = (preference) ->
      preference.value = preference.original_value
  ]).service('LoadingInterceptor', ['$q', '$rootScope', ($q, $rootScope) ->
    return {
        request: (config) ->
            $rootScope.errorMode = false
            return config
        requestError: (rejection) ->
            $rootScope.errorMode = true
            $rootScope.errorMessage = rejection
            return $q.reject(rejection)
        response: (response) ->
          $rootScope.errorMode = false
          return response;
        responseError: (rejection) ->
          # TODO Need to make error handling work better.
          $rootScope.errorMode = true
          console.log rejection
          key = rejection["config"]["data"]["key"]
          scope = angular.element('[ng-controller=PreferenceCtrl]').scope()
          for preference in scope.preferences
            if preference.key == key
              console.log preference
              message = preference.displayKey() + ": " + rejection["data"]["value"][0]
              $rootScope.errorMessage = message
              alert message
              break
          return $q.reject(rejection)
    };
  ])