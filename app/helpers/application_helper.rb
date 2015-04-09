module ApplicationHelper
  def active_nav(nav)
    return :active if controller_name == nav
    return :active if controller_path.split('/')[0] == nav
  end

  def version
    content_tag(:pre, class: "version", style: "float: right;") do
      ("CobbleBot version: #{COBBLEBOT_VERSION}").html_safe
    end
  end
  
  def sortable_header_link(name, field)
    sort_order = params[:sort_order] == 'asc' ? 'desc' : 'asc'
    current_field = params[:sort_field] || @sort_field
    name = "#{name} #{sort_order == 'desc' ? '⬆︎' : '⬇︎'}" if !!current_field && current_field == field
    options = params.merge(action: controller.action_name, sort_field: field, page: nil, query: params[:query], sort_order: sort_order)
    
    link_to name, url_for(options)
  end
  
  def created(created_at)
    "#{distance_of_time_in_words_to_now(created_at)} ago"
  end
  
  def modal_nav_links(path, id)
    link_to(path, id: "first_#{id}", class: 'btn btn-default', accesskey: 'f', data: { remote: true, target: "#show_#{id}"}) do
      content_tag(:u) { 'F' } + 'irst'
    end +
    link_to(path, id: "previous_#{id}", class: 'btn btn-default', accesskey: 'p', data: { remote: true, target: "#show_#{id}"}) do
      content_tag(:u) { 'P' } + 'revious'
    end +
    link_to(path, id: "next_#{id}", class: 'btn btn-default', accesskey: 'n', data: { remote: true, target: "#show_#{id}"}) do
      content_tag(:u) { 'N' } + 'ext'
    end +
    link_to(path, id: "last_#{id}", class: 'btn btn-default', accesskey: 'l', data: { remote: true, target: "#show_#{id}"}) do
      content_tag(:u) { 'L' } + 'ast'
    end
  end
  
  def link_remote_delete(action, options = {class: 'btn btn-danger', confirm: 'Are you sure?'})
    link_to 'Delete', action, class: options[:class], data: { confirm: options[:confirm], remote: true, method: :delete }
  end
end
