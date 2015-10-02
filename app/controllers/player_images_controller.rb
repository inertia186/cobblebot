class PlayerImagesController < ApplicationController
  skip_before_action :check_server_status
  caches_action :show, expires_in: 2.hours

  def show
    uuid = request.env["HTTP_IF_NONE_MATCH"]
    head 304 and return if !!uuid && !uuid.empty?

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
      uuid ||= Player.find_by_nick(nick).uuid rescue nil
      response.headers['Expires'] = 2.hours.from_now.httpdate
      response.headers['Cache-Control'] = "max-age=#{2.hours.from_now.to_i / 1000}, public"
      response.headers['Pragma'] = 'cache'
      response.headers['ETag'] = uuid unless uuid.to_s.empty?
      send_data image, stream: false, filename: "#{nick}.#{format}", type: "image/#{format}", disposition: 'inline'
    else
      redirect_to url
    end
  end
end
