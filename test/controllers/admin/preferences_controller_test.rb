require 'test_helper'

class Admin::PreferencesControllerTest < ActionController::TestCase
  def setup
    session[:admin_signed_in] = true
  end

  def test_routings
    assert_routing('admin/preferences', controller: 'admin/preferences', action: 'index')
    assert_routing('admin/preferences/edit_cell', controller: 'admin/preferences', action: 'edit_cell')
    assert_routing({ method: 'patch', path: 'admin/preferences/42' }, controller: 'admin/preferences', action: 'update', id: '42')
  end

  def test_index
    get :index

    assert_template :index
    assert_response :success
  end

  def test_index_json
    get :index, params: { format: :json }

    assert JSON.parse(response.body), 'expect valid json'

    assert_template :index
    assert_response :success
  end

  def test_index_redacts_secure_values_from_json_and_html
    preference = preferences(:irc_nickserv_password)
    secret = preference.value

    get :index, params: { format: :json }

    rendered = JSON.parse(response.body).find { |item| item['key'] == preference.key }
    assert_nil rendered['value']
    assert_equal true, rendered['secure']
    assert_equal true, rendered['has_value']
    refute_includes response.body, secret
    assert_equal 'no-store', response.headers['Cache-Control']

    get :index

    refute_includes response.body, secret
    assert_equal 'no-store', response.headers['Cache-Control']
    assert_equal 'no-cache', response.headers['Pragma']
  end

  def test_edit_cell
    get :edit_cell

    assert_template :edit_cell
    assert_response :success
  end

  def test_update
    preference = Preference.first
    preference_params = {
      value: 'value'
    }

    patch :update, params: { format: :json, id: preference, preference: preference_params }

    preference = assigns :preference
    assert preference.errors.empty?, preference.errors.inspect

    assert_template nil
    assert_response :success
  end

  def test_blank_secure_update_preserves_the_existing_value
    preference = preferences(:irc_nickserv_password)
    original_value = preference.value

    patch :update, params: {
      format: :json, id: preference, preference: { value: '' }
    }

    assert_response :accepted
    assert_equal original_value, preference.reload.value
    assert_equal 'no-store', response.headers['Cache-Control']
  end

  def test_secure_update_accepts_a_replacement_without_returning_it
    preference = preferences(:irc_nickserv_password)
    replacement = 'replacement-secret'

    patch :update, params: {
      format: :json, id: preference, preference: { value: replacement }
    }

    assert_response :accepted
    assert_equal replacement, preference.reload.value
    refute_includes response.body, replacement
  end

  def test_update_rejects_invalid_json
    preference = Preference.where("key LIKE '%_json'").first
    preference_params = {
      value: 'WRONG'
    }

    patch :update, params: { format: :json, id: preference, preference: preference_params }

    preference = assigns :preference
    assert_equal 1, preference.errors[:value].size
    assert_match(/\Ahas a problem on line 1:/, preference.errors[:value].first)
    assert_equal preference.errors.as_json, JSON.parse(response.body).symbolize_keys

    assert_template nil
    assert_response :unprocessable_entity
  end

  def test_update_rejects_a_missing_server_path
    patch :update, params: {
      format: :json,
      id: Preference::PATH_TO_SERVER,
      preference: { value: Rails.root.join('missing-minecraft-server').to_s }
    }

    preference = assigns :preference
    assert_equal ['does not exist.'], preference.errors[:value]
    assert_equal preference.errors.as_json, JSON.parse(response.body).symbolize_keys
    assert_response :unprocessable_entity
  end

  def test_update_rejects_a_non_integer_irc_port
    patch :update, params: {
      format: :json,
      id: Preference::IRC_SERVER_PORT,
      preference: { value: 'not-a-port' }
    }

    preference = assigns :preference
    assert_equal [
      'must be a valid integer.',
      'must be a valid port number (1 to 65535).'
    ], preference.errors[:value]
    assert_equal preference.errors.as_json, JSON.parse(response.body).symbolize_keys
    assert_response :unprocessable_entity
  end
end
