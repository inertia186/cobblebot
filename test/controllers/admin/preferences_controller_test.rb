require 'test_helper'

class Admin::PreferencesControllerTest < ActionController::TestCase
  def setup
    sym = :create!; eval File.read "#{Rails.root}/db/seeds.rb"
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
end