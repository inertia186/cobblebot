require 'digest'

class Api::V1::ApiController < ApplicationController
  before_action :require_valid_admin_token!

  respond_to :json

private
  def require_valid_admin_token!
    authenticate_or_request_with_http_token do |token, _options|
      expected_token = Preference.web_admin_password.to_s
      valid = expected_token.present? && ActiveSupport::SecurityUtils.secure_compare(
        Digest::SHA256.hexdigest(token),
        Digest::SHA256.hexdigest(expected_token)
      )

      @current_token = token if valid
      valid
    end
  end
end
