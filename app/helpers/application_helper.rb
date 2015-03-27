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
    name = "#{name} #{sort_order == 'asc' ? '⬆︎' : '⬇︎'}" if !!current_field && current_field == field
    options = params.merge(action: controller.action_name, sort_field: field, page: nil, query: params[:query], sort_order: sort_order)
    
    link_to name, url_for(options)
  end
  
  def created(created_at)
    "#{distance_of_time_in_words_to_now(created_at)} ago"
  end
end
