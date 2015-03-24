require 'test_helper'

class Admin::SessionsControllerTest < ActionController::TestCase
  def setup
    sym = :create!; eval File.read "#{Rails.root}/db/seeds.rb"
  end

  def test_routings
    assert_routing({ method: 'get', path: 'admin/sessions/new' }, controller: 'admin/sessions', action: 'new')
    assert_routing({ method: 'post', path: 'admin/sessions' }, controller: 'admin/sessions', action: 'create')
    assert_routing({ method: 'delete', path: 'admin/session' }, controller: 'admin/sessions', action: 'destroy')
  end
  
  def test_new
    get :new

    assert_template :new
    assert_response :success
  end

  def test_create
    post :create, admin_password: Preference.web_admin_password

    assert_template nil
    assert_redirected_to admin_preferences_url
  end

  def test_destroy
    get :destroy

    assert_template nil
    assert_redirected_to new_admin_session_url
  end
end