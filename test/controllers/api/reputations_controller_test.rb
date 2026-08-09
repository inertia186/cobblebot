require 'test_helper'

class Api::V1::ReputationsControllerTest < ActionController::TestCase
  def setup
    @truster = players(:inertia186)
    @trustee = players(:Dinnerbone)
    @reputation = Reputation.create!(truster: @truster, trustee: @trustee, rate: 3)
    request_token Preference.web_admin_password
  end

  def test_routings
    assert_routing 'api/reputations', controller: 'api/v1/reputations', action: 'index', format: 'json'
    assert_routing 'api/reputations/42', controller: 'api/v1/reputations', action: 'show', id: '42', format: 'json'
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

  def test_index_exposes_distinct_truster_and_trustee_data
    get :index, params: {format: :json}

    json = response_json.detect { |row| row['rate'] == @reputation.rate }
    assert_response :success
    assert_equal @truster.uuid, json['trusters_uuid']
    assert_equal @truster.nick, json['trusters_nick']
    assert_equal @trustee.uuid, json['trustees_uuid']
    assert_equal @trustee.nick, json['trustees_nick']
  end

  def test_index_filters_by_truster_nickname
    get :index, params: {format: :json, any_truster_nick: @truster.nick}

    assert_equal [@reputation.id], assigns(:reputations).map(&:id)
    assert_response :success
  end

  def test_index_filters_by_trustee_nickname
    get :index, params: {format: :json, any_trustee_nick: @trustee.nick}

    assert_equal [@reputation.id], assigns(:reputations).map(&:id)
    assert_response :success
  end

  def test_index_ignores_blank_nickname_filters
    get :index, params: {
      format: :json,
      any_truster_nick: '',
      any_trustee_nick: ''
    }

    assert_response :success
    assert_equal Reputation.order(:id).pluck(:id),
      assigns(:reputations).order(:id).pluck(:id)
  end

  def test_show
    get :show, params: {id: @reputation, format: :json}

    assert_response :success
    assert_equal @truster.nick, response_json['trusters_nick']
    assert_equal @trustee.nick, response_json['trustees_nick']
    assert_equal @reputation.rate, response_json['rate']
  end
end
