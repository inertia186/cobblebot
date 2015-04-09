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
    nav_link(path, "first_#{id}", 'f', "#show_#{id}", 'F', 'irst') +
    nav_link(path, "previous_#{id}", 'p', "#show_#{id}", 'P', 'revious') +
    nav_link(path, "next_#{id}", 'n', "#show_#{id}", 'N', 'ext') +
    nav_link(path, "last_#{id}", 'l', "#show_#{id}", 'L', 'ext')
  end
  
  def link_remote_delete(action, options = {class: 'btn btn-danger', confirm: 'Are you sure?'})
    link_to 'Delete', action, class: options[:class], data: { confirm: options[:confirm], remote: true, method: :delete }
  end
private
  def nav_link(path, id, target, accesskey, prefix, suffix)
    link_to(path, id: id, class: 'btn btn-default', accesskey: accesskey, data: { remote: true, target: target}) do
      content_tag(:u) { prefix } + suffix
    end
  end
end
