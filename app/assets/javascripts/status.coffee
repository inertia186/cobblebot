if document.app == undefined
  document.app = angular.module("CobbleBot", ["ngResource"])

document.app.
controller('StatCtrl', ['$scope', 'Stat', ($scope, Stat) ->
  $scope.status = Stat.query()
])
