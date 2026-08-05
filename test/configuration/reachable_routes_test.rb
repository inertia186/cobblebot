require 'test_helper'

class ReachableRoutesTest < ActiveSupport::TestCase
  def test_retired_api_session_routes_are_absent
    %i[post put patch delete].each do |method|
      assert_raises(ActionController::RoutingError) do
        Rails.application.routes.recognize_path('/api/session', method: method)
      end
    end
  end

  def test_retired_admin_console_route_is_absent
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path('/admin/config/console', method: :get)
    end
  end
end
