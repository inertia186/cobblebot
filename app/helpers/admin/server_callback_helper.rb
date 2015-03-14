module Admin::ServerCallbackHelper
  def callback_status_class(callback)
    return 'warning' unless callback.enabled?
    return 'warning' unless callback.ready?
      
    'success'
  end
end

