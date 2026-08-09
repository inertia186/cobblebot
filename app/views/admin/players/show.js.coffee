$('#show_player_label').replaceWith('<h4 class="modal-title" id="show_player_label"><img lowsrc="<%= player_images_path(id: @player.nick, size: 16, format: 'png') %>" src="<%= player_images_path(id: @player.nick, size: 32, format: 'png') %>" width="32" height="32" /> <%= @player.nick %></h4>');
$('#show_player_body').replaceWith('<div class="modal-body" id="show_player_body"><%= j render 'player', player: @player, modal: 'true' %></div>');

current_player_row = $('#player_tr_<%= @player.id %>')

first_player_row = current_player_row.siblings().first()
previous_player_row = current_player_row.prev()
next_player_row = current_player_row.next()
last_player_row = current_player_row.siblings().last()

first_button = $('#first_player')
previous_button = $('#previous_player')
next_button = $('#next_player')
last_button = $('#last_player')

configure_nav = (button, row, disabled) ->
  button.off('.playerNavigation')
  if disabled || row.length == 0 || !row.data('id')
    button.addClass('disabled').attr('aria-disabled', 'true').removeAttr('href')
    button.on 'click.playerNavigation', (event) -> event.preventDefault()
  else
    button.removeClass('disabled').removeAttr('aria-disabled')
    button.attr('href', '<%= j admin_players_path %>/' + row.data('id'))

configure_nav first_button, first_player_row,
  first_player_row.length == 0 || first_player_row.data('id') == next_player_row.data('id')
configure_nav previous_button, previous_player_row, previous_player_row.length == 0
configure_nav next_button, next_player_row, next_player_row.length == 0
configure_nav last_button, last_player_row,
  last_player_row.length == 0 || last_player_row.data('id') == previous_player_row.data('id')
