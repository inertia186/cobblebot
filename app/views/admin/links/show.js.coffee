$('#show_link_label').replaceWith('<h4 class="modal-title" id="show_link_label"><%= @link.title %></h4>');
$('#show_link_body').replaceWith('<div class="modal-body" id="show_link_body"><%= j render 'link', link: @link, modal: 'true' %></div>');

current_link_row = $('#link_tr_<%= @link.id %>')

first_link_row = current_link_row.siblings().first()
previous_link_row = current_link_row.prev()
next_link_row = current_link_row.next()
last_link_row = current_link_row.siblings().last()

first_button = $('#first_link')
previous_button = $('#previous_link')
next_button = $('#next_link')
last_button = $('#last_link')

if first_link_row.length == 0 || first_link_row.data('id') == next_link_row.data('id')
  first_button.attr('disabled', 'disabled')

if previous_link_row.length == 0
  previous_button.attr('disabled', 'disabled')

if next_link_row.length == 0
  next_button.attr('disabled', 'disabled')

if last_link_row.length == 0 || last_link_row.data('id') == previous_link_row.data('id')
  last_button.attr('disabled', 'disabled')

first_button.click ->
  id = first_link_row.data('id')
  @href = @href + '/' + id

previous_button.click ->
  id = previous_link_row.data('id')
  @href = @href + '/' + id

next_button.click ->
  id = next_link_row.data('id')
  @href = @href + '/' + id

last_button.click ->
  id = last_link_row.data('id')
  @href = @href + '/' + id

