require 'test_helper'

class Admin::PreferencesControllerTest < ActionController::TestCase
  def setup
    session[:admin_signed_in] = true

    stub_request(:post, "https://slack.com/api/auth.test").
      with(body: {"token" => true}, headers: {
        'Accept' => 'application/json; charset=utf-8', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/x-www-form-urlencoded', 'User-Agent' => 'Slack Ruby Gem 1.1.6'
      }).
      to_return(status: 200, body: "")
  end

  def test_routings
    assert_routing('admin/preferences', controller: 'admin/preferences', action: 'index')
    assert_routing({ method: 'patch', path: 'admin/preferences/42' }, controller: 'admin/preferences', action: 'update', id: '42')
  end

  def test_index
    get :index

    assert_template :index
    assert_response :success
  end

  def test_index_json
    get :index, format: :json

    assert JSON.parse(response.body), 'expect valid json'

    assert_template :index
    assert_response :success
  end

  def test_update
    preference = Preference.first
    preference_params = {
      value: 'value'
    }

    post :update, format: :json, id: preference, preference: preference_params

    preference = assigns :preference
    assert preference.errors.empty?, preference.errors.inspect

    assert_template nil
    assert_response :success
  end

  def test_update_fail
    preference = Preference.where("key LIKE '%_json'").first
    preference_params = {
      value: 'WRONG'
    }

    post :update, format: :json, id: preference, preference: preference_params

    preference = assigns :preference
    refute preference.errors.empty?

    assert_template nil
    assert_response :unprocessable_entity
  end
end
