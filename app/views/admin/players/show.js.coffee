$('#show_player_label').replaceWith('<h4 class="modal-title" id="show_player_label"><img lowsrc="https://minotar.net/avatar/<%= @player.nick %>/16.png" src="https://minotar.net/avatar/<%= @player.nick %>/32.png" width="32" height="32" /> <%= @player.nick %></h4>');
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

if first_player_row.length == 0 || first_player_row.data('id') == next_player_row.data('id')
  first_button.attr('disabled', 'disabled')

if previous_player_row.length == 0
  previous_button.attr('disabled', 'disabled')

if next_player_row.length == 0
  next_button.attr('disabled', 'disabled')

if last_player_row.length == 0 || last_player_row.data('id') == previous_player_row.data('id')
  last_button.attr('disabled', 'disabled')

first_button.click ->
  id = first_player_row.data('id')
  @href = @href + '/' + id

previous_button.click ->
  id = previous_player_row.data('id')
  @href = @href + '/' + id

next_button.click ->
  id = next_player_row.data('id')
  @href = @href + '/' + id

last_button.click ->
  id = last_player_row.data('id')
  @href = @href + '/' + id

