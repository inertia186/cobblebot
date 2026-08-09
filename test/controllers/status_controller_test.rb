require 'test_helper'

class StatusControllerTest < ActionController::TestCase
  def test_routing
    assert_routing '/status', controller: 'status', action: 'index'
  end

  def test_index_json_serializes_query_values
    query = {numplayers: '2', checked_at: Time.zone.at(123)}

    Server.mock_mode(up: true) do
      ServerQuery.mock_mode(full_query: query) do
        get :index, params: {format: :json, 'angular.version' => 'test-client'}
      end
    end

    assert_response :success
    assert_equal [
      {'key' => 'numplayers', 'value' => '2'},
      {'key' => 'checked_at', 'value' => 123},
      {'key' => 'angular.version', 'value' => 'test-client'}
    ], response_json
  end
end
