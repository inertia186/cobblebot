$('#show_callback_label').replaceWith('<h4 class="modal-title" id="show_callback_label"><%= @callback.name %></h4>');
$('#show_callback_body').replaceWith('<div class="modal-body" id="show_callback_body"><%= j render 'callback', callback: @callback, modal: 'true' %></div>');

current_callback_row = $('#callback_tr_<%= @callback.id %>')

first_callback_row = current_callback_row.siblings().first()
previous_callback_row = current_callback_row.prev()
next_callback_row = current_callback_row.next()
last_callback_row = current_callback_row.siblings().last()

first_button = $('#first_callback')
previous_button = $('#previous_callback')
next_button = $('#next_callback')
last_button = $('#last_callback')

if first_callback_row.length == 0 || first_callback_row.data('id') == next_callback_row.data('id')
  first_button.attr('disabled', 'disabled')

if previous_callback_row.length == 0
  previous_button.attr('disabled', 'disabled')

if next_callback_row.length == 0
  next_button.attr('disabled', 'disabled')

if last_callback_row.length == 0 || last_callback_row.data('id') == previous_callback_row.data('id')
  last_button.attr('disabled', 'disabled')

first_button.click ->
  id = first_callback_row.data('id')
  @href = @href + '/' + id

previous_button.click ->
  id = previous_callback_row.data('id')
  @href = @href + '/' + id

next_button.click ->
  id = next_callback_row.data('id')
  @href = @href + '/' + id

last_button.click ->
  id = last_callback_row.data('id')
  @href = @href + '/' + id

