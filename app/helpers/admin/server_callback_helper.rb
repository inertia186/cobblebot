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
end
