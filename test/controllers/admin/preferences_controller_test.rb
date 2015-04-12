require 'test_helper'

class Admin::PreferencesControllerTest < ActionController::TestCase
  def setup
    seed
    session[:admin_signed_in] = true
  end

  def test_routings
    assert_routing({ method: 'get', path: 'admin/preferences' }, controller: 'admin/preferences', action: 'index')
    assert_routing({ method: 'get', path: 'admin/preferences/42/edit' }, controller: 'admin/preferences', action: 'edit', id: '42')
  end
  
  def test_index
    get :index
    preferences = assigns :preferences
    refute_equal preferences.count, 0, 'did not expect zero count'
    
    assert_template :index
    assert_response :success
  end
  
  def test_edit
    get :edit, id: Preference.first
    preference = assigns :preference
    assert preference, 'expect preference'
    
    assert_template :edit
    assert_response :success
  end
  
  def test_update
    preference = Preference.first
    preference_params = {
      value: 'value'
    }
    
    post :update, id: preference, preference: preference_params
    
    preference = assigns :preference
    assert preference.errors.empty?, preference.errors.inspect
    
    assert_redirected_to admin_preferences_url
  end
end