module Admin::ServerCallbackHelper
  def callback_ran(callback)
    if !!callback.ran_at
      "#{distance_of_time_in_words_to_now(callback.ran_at)} ago"
    else
      'Never'
    end
  end
  
  def callback_status_class(callback)
    return 'warning' unless callback.enabled?
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
  
  def callback_toggle_enabled(callback)
    if callback.enabled?
      'Disable'
    else
      'Enable'
    end
  end

  def callback_created(callback)
    "#{distance_of_time_in_words_to_now(callback.created_at)} ago"
  end
  
  def callback_run_link(callback, options = {class: 'btn btn-success'})
    link_to 'Run', execute_command_admin_server_callback_path(callback), class: options[:class], data: { remote: true }
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
