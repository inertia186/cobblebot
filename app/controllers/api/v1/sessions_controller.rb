class Api::V1::SessionsController < Api::V1::ApiController
  def create
    if Preference.web_admin_passwrod == params[:password]
      # TODO save new access token
      render status: 201
    else
      render_errors "Authentication failure.", 401
    end
  end

  def destroy
    # TODO deltete access token
    head 204
  end
end
