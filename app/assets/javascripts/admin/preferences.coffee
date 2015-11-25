if document.app == undefined
  document.app = angular.module("CobbleBot", ["ngResource"])

document.app.
controller('PreferenceCtrl', ['$scope', 'Preference', ($scope, Preference) ->
  $scope.preferences = Preference.query()

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
