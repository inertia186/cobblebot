document.onload = function() {
  var __injector__ = angular.element(document).injector();
  var __log__ = __injector__.get('$log');
  __log__.error = __tattle__;
  console.log("Registered error tattle.");
};

function __tattle__(error) {
  console.log('ANGULAR TRIED TO HIDE AN ERROR:', error);
  throw(error);
}