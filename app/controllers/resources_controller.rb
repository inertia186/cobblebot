require 'digest/sha2'

class ResourcesController < ApplicationController
  def server_icon
    server_icon = Server.server_icon

    return render(file: "#{Rails.root}/public/404.html", status: :not_found) unless server_icon

    expires_in 2.hours, public: true
    return unless stale?(etag: Digest::SHA256.hexdigest(server_icon))

    send_data server_icon, filename: 'server-icon.png', type: 'image/png', disposition: 'inline'
  end
end
