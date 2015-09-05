// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require bootstrap.min
//= require_tree .

$(function () {
  if ( $("#public-players").length > 0 ) {
    setTimeout(updatePublicPlayers, 5000);
    
    $('body').on('click', '#chat_controls', function(e) {
      chat = $("#chat")
      chat.slideToggle('slow')
    })
  }
});

function updatePublicPlayers() {
  var after = $("#last_chat").attr("data-last-chat-at");

  $.getScript("/players.js?after=" + after)
  
  setTimeout(updatePublicPlayers, 5000);
}