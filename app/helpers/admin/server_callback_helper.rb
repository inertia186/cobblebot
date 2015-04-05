module Admin::ServerCallbackHelper
  def callback_status_options_for_select(default = nil)
    options = [['Status', ''], ['Ready', 'ready'], ['In Cooldown', 'in_cooldown'], ['Enabled', 'enabled'], ['Disabled', 'disabled']]

    options.map do |option|
      if default == option[1]
        content_tag(:option, option[0], value: option[1], selected: 'selected')
      else
        content_tag(:option, option[0], value: option[1])
      end
    end.join.html_safe
  end
  
  def callback_type_options_for_select(default = nil)
    label_option = "Type"
    options = [label_option] + ServerCallback::ALL_TYPES

    options.map do |option|
      display_option = option.split('::')[1..-1].join(' ').titleize
      if option == label_option
        content_tag(:option, option, value: '')
      elsif default == option
        content_tag(:option, display_option, value: option, selected: 'selected')
      else
        content_tag(:option, display_option, value: option)
      end
    end.join.html_safe
  end
  
  def callback_ran(callback)
    if !!callback.ran?
      "#{distance_of_time_in_words_to_now(callback.ran_at)} ago"
    else
      'Never'
    end
  end
  
  def callback_status_class(callback)
    return 'warning' unless callback.enabled?
    return 'danger' if callback.error_flag?
    return 'warning' unless callback.ready?
      
    'success'
  end
  
  def callback_status(callback)
    if callback.enabled?
      if callback.ready?
        'Ready'
      else
        'In Cooldown'
      end
    else
      'Disabled'
    end
  end
  
  def callback_last_match(callback)
    return if callback.last_match.nil?
    
    # FIXME Using the original way instead, without highlighting.  See below.
    content_tag(:code, id: "callback_last_match_#{callback.id}") do
      callback.last_match
    end
    
    # FIXME This is a failed attempt to highlight matched substrings.
    # content_tag(:code, id: "callback_last_match_#{callback.id}") do
    #   pattern = callback.pattern
    #   pattern.gsub!(/\(/, '')
    #   pattern.gsub!(/\)/, '')
    #   pattern.gsub!(/\/\^/, '/')
    #   pattern.gsub!(/\$\//, '/')
    #   last_match = Rack::Utils.escape_html(callback.last_match.html_safe)
    # 
    #   if match = last_match.scan(eval(pattern, Proc.new{}.binding)).flatten
    #     replacements = match.map do |substring|
    #       content_tag(:span, style: 'text-decoration: underline;') do
    #         substring
    #       end
    #     end
    # 
    #     match.each_with_index do |substring, i|
    #       last_match.sub!(substring, replacements[i])
    #     end
    #     
    #     last_match.html_safe
    #   else
    #     last_match
    #   end
    # end
  end
  
  def callback_toggle_enabled(callback)
    if callback.enabled?
      'Disable'
    else
      'Enable'
    end
  end

  def callback_run_link(callback, options = {class: 'btn btn-success'})
    link_to 'Run', execute_command_admin_server_callback_path(callback), class: options[:class], data: { remote: true }
  end
  
  # TODO Figure out if there's a simple way to just start a gist without
  # implementing the full gist api.
  def callback_gist_link(callback, options = {class: 'btn btn-success'})
    return nil
    
    link_to 'Gist', gist_callback_admin_server_callback_path(callback), class: options[:class], target: :gist
  end
  
  def callback_edit_link(callback, options = {class: 'btn btn-info btn'})
    link_to 'Edit', edit_admin_server_callback_path(callback), class: options[:class]
  end
  
  def callback_reset_link(callback, options = {class: 'btn btn-warning'})
    link_to 'Reset', reset_cooldown_admin_server_callback_path(callback), class: options[:class], data: { confirm: 'Are you sure?  This will reset the entire callback, including any debugging information.', remote: true, method: :patch }
  end
  
  def callback_enable_link(callback, options = {class: 'btn btn-info'})
    link_to callback_toggle_enabled(callback), toggle_enabled_admin_server_callback_path(callback), class: options[:class], data: { remote: true, method: :patch }
  end
  
  def callback_delete_link(callback, options = {class: 'btn btn-danger'})
    link_to 'Delete', admin_server_callback_path(callback), class: options[:class], data: { confirm: 'Are you sure?', remote: true, method: :delete }
  end
end
