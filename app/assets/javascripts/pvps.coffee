if document.app == undefined
  document.app = angular.module("CobbleBot", ["ngResource"])

document.app.
controller('PvpCtrl', ['$scope', '$timeout', 'Pvp', ($scope, $timeout, Pvp) ->
  $scope.showCount = false
  $scope.pvps = Pvp.query()
  $scope.didSearch = ->
    $scope.showCount = false
    $scope.countFrom = 0
    clearTimeout($scope.lastSearchId)
    apply = -> $scope.$apply -> $scope.showCount = true
    $scope.lastSearchId = $timeout(apply, 250)
  $scope.repeatComplete = ->
    $scope.showCount = true
    $scope.countFrom = Math.round($scope.filteredPvps.length / 1.01)
]).
filter('searchFor', ['$rootScope', ($rootScope) -> (pvps, searchString) ->
  return pvps if !searchString
  
  result = []
  searchString = searchString.toLowerCase()
  angular.forEach pvps, (item) ->
    text = item.body.toLowerCase()
    text += item.loser.quote if !!item.loser
    text += item.winner.quote if !!item.winner
    result.push(item) if text.indexOf(searchString) != -1
  
  result
])
