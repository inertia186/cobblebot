if document.app == undefined
  document.app = angular.module("CobbleBot", ["ngResource"])

document.app.
controller('PvpCtrl', ['$scope', '$timeout', 'Pvp', ($scope, $timeout, Pvp) ->
  $scope.showCount = false
  $scope.pvps = Pvp.query()
  $scope.didSearch = ->
    $scope.showCount = false
    $scope.countFrom = 0
    $timeout.cancel($scope.lastSearchId) if $scope.lastSearchId
    $scope.lastSearchId = $timeout((-> $scope.showCount = true), 250)
  $scope.repeatComplete = ->
    $scope.showCount = true
    len = $scope.filteredPvps.length
    $scope.countFrom = Math.round(len / 1.01)
])
