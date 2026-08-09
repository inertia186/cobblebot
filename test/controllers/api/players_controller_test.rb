require 'test_helper'

class Api::V1::PlayersControllerTest < ActionController::TestCase
  def setup
    request_token Preference.web_admin_password
  end

  def test_routings
    assert_routing 'api/players', controller: 'api/v1/players', action: 'index', format: 'json'
    assert_routing 'api/players/42', controller: 'api/v1/players', action: 'show', id: '42', format: 'json'
  end

  def test_index
    get :index, params: { format: :json, only_registered: true }
    assert_response 200

    assert_equal 1, response_json.size

    assert_template :index
    assert_template partial: "api/v1/players/_minimal_player"
  end

  def test_index_any_nick
    target = Player.find_by_nick 'inertia186'
    nonmatching = Player.find_by_nick('Dinnerbone')
    nonmatching.update!(registered_at: Time.current)
    get :index, params: { format: :json, only_registered: true, any_nick: target.nick }
    assert_response 200

    assert_equal 1, response_json.size
    assert_equal [target.uuid], response_json.map { |json| json['uuid'] }
    refute_includes response_json.map { |json| json['uuid'] }, nonmatching.uuid

    response_json.each do |json|
      player = Player.find_by_uuid(json['uuid'])
      refute_nil player

      %w(uuid nick registered_at).each do |attr|
        assert_equal player.send(attr), json[attr]
      end
    end

    assert_template :index
    assert_template partial: "api/v1/players/_minimal_player"
  end

  def test_index_does_not_treat_false_as_only_registered
    get :index, params: {format: :json, only_registered: 'false'}

    assert_response :success
    assert_equal Player.order(:id).pluck(:id), assigns(:players).order(:id).pluck(:id)
  end

  def test_index_ignores_blank_value_filters
    get :index, params: {format: :json, any_nick: '', origin: '', cc: ''}

    assert_response :success
    assert_equal Player.order(:id).pluck(:id), assigns(:players).order(:id).pluck(:id)
  end

  def test_index_rejects_a_missing_token
    @request.headers['Authorization'] = nil

    get :index, params: {format: :json}

    assert_response :unauthorized
  end

  def test_index_rejects_an_invalid_token
    request_token 'invalid-token'

    get :index, params: {format: :json}

    assert_response :unauthorized
  end

  def test_show
    player = Player.find_by_nick 'inertia186'
    get :show, params: { id: player.id, format: :json }
    assert_response 200
    %w(uuid nick registered_at).each do |attr|
      assert_equal player.send(attr), response_json[attr]
    end

    assert_template :show
    assert_template partial: "api/v1/players/_minimal_player"
  end
end
