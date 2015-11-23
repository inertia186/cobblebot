if document.app == undefined
  document.app = angular.module("CobbleBot", ["ngResource"])

document.app.
  factory('Donation', ['$resource', 'resourceCache', ($resource, resourceCache) ->
    Donation = $resource "/donations/:id.json",
    {id: "@id"},
    {query: {cache: resourceCache, isArray: true}}
    decorateDonationType angular, Donation
    
    Donation
  ]).
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
      $scope.countFrom = Math.round($scope.filteredDonations.length / 1.01)
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
  
decorateDonationType = (angular, type) ->
  angular.extend type.prototype,
    createdAgo: -> moment(@created_at).fromNow()
