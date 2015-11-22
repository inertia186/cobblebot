if document.app == undefined
  document.app = angular.module("CobbleBot", ["ngResource"])

document.app.
  factory('Stat', ['$resource', ($resource) ->
    Stat = $resource "/status/:key.json", { key: "@key" }
    decorateStatType angular, Stat
    
    Stat
  ]).
  factory("PreloadedStat", ['$resource', '$cacheFactory', '$window', 'Stat', ($resource, $cacheFactory, $window, Stat) ->
    cached = $window.preloadedStatus
    angular.forEach cached, (item, key) ->
      cached[key] = new Stat(key: key, value: item)

    $cacheFactory.get('$http').put '/status.json', cached

    PreloadedStat = $resource "/status/:key.json",
      {key: "@key"},
      {query: {cache: true}}
    decorateStatType angular, PreloadedStat

    PreloadedStat
  ]).
  controller('StatCtrl', ['$scope', 'Stat', 'PreloadedStat', ($scope, Stat, PreloadedStat) ->
    $scope.status = PreloadedStat.query()
  ])
  
decorateStatType = (angular, type) ->
  angular.extend type.prototype,
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
