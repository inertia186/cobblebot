if document.app == undefined
  document.app = angular.module("CobbleBot", ["ngResource"])

document.app.
controller('DonationCtrl', ['$scope', 'Donation', ($scope, Donation) ->
  $scope.showCount = false
  $scope.donations = Donation.query()
  $scope.didSearch = ->
    $scope.showCount = false
    $scope.countFrom = 0
    clearTimeout($scope.lastSearchId)
    apply = -> $scope.$apply -> $scope.showCount = true
    $scope.lastSearchId = setTimeout(apply, 250)
  $scope.repeatComplete = ->
    $scope.showCount = true
    len = $scope.filteredDonations.length
    $scope.countFrom = Math.round(len / 1.01)
]).
filter('searchFor', ['$rootScope', ($rootScope) -> (donations, searchString) ->
  return donations if !searchString
  
  result = []
  searchString = searchString.toLowerCase()
  angular.forEach donations, (item) ->
    text = item.body.toLowerCase()
    text += item.author.quote if !!item.author
    result.push(item) if text.indexOf(searchString) != -1
  
  result
])
