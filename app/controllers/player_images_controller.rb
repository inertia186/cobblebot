require 'digest'

class PlayerImagesController < ApplicationController
  skip_before_action :check_server_status
  caches_action :show, expires_in: 2.hours

  def show
    nick = params[:id]
    size = params[:size] || 16
    format = params[:format] || 'png'

    url = "https://minotar.net/avatar/#{nick}/#{size}.#{format}"

    begin
      agent = CobbleBotAgent.new
      agent.get url
      image = if agent.page.code == '200'
        agent.page.body
      else
        File.read('public/images/steve.png')
      end
    rescue StandardError => e
      Rails.logger.error e.inspect
      image = File.read('public/images/steve.png')
    end

    if !!image
      response.headers['Expires'] = 2.hours.from_now.httpdate
      expires_in 2.hours, public: true
      response.headers['Pragma'] = 'cache'
      return unless stale?(
        strong_etag: Digest::SHA256.hexdigest(image),
        public: true
      )

      send_data image, stream: false, filename: "#{nick}.#{format}", type: "image/#{format}", disposition: 'inline'
    else
      redirect_to url, allow_other_host: true
    end
  end
end
