class PlayerImagesController < ApplicationController
  caches_action :show

  def show
    nick = params[:id]
    size = params[:size] || 16
    format = params[:format] || 'png'
    url = "https://minotar.net/avatar/#{nick}/#{size}.#{format}"

    begin
      agent = CobbleBotAgent.new
      agent.get url
      image = agent.page.body
    rescue StandardError => e
      Rails.logger.error e.inspect
    end

    if !!image
      send_data image, stream: false, filename: "#{nick}.#{format}", type: "image/#{format}", disposition: 'inline'
    else
      redirect_to url
    end
  end
end
