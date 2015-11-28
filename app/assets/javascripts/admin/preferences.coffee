if document.app == undefined
  document.app = angular.module("CobbleBot", ["ngResource"])

document.app.
controller('PreferenceCtrl', ['$scope', '$rootScope', 'Preference', ($scope, $rootScope, Preference) ->
  $scope.preferences = Preference.query()

  $scope.edit = (preference) ->
    preference.original_value = preference.value
    $scope.checkStrength(preference) if preference.isSecure()
  $scope.save = (preference) ->
    Preference.update(preference.key, preference, ->
      $scope.rowErrorMessage = ''
    , (response) ->
      status = response["status"]
      $scope.rowErrorMessage = switch status
        # Unprocessable Entity
        when 422 then preference.displayKey() + ' ' + response['data']['value'][0]
        else response['statusText']
      $scope.editMode = true
    )
  $scope.cancel = (preference) ->
    $scope.rowErrorMessage = ''
    preference.value = preference.original_value
  $scope.checkStrength = (preference) ->
    if preference.value.length >= 8
      $scope.strength = 'strong';
    else if preference.value.length >= 6
      $scope.strength = 'medium'
    else
      $scope.strength = 'weak'
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
