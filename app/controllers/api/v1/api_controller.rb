class Api::V1::ApiController < ApplicationController
  #before_action :require_valid_admin_token!

  respond_to :json
  
  def require_valid_admin_token!
    # TODO
    authenticate_or_request_with_http_token do |token, options|
      @current_token = token

      true
    end
  end
end