require 'test_helper'

class Admin::LinksControllerTest < ActionController::TestCase
  def setup
    sym = :create!; eval File.read "#{Rails.root}/db/seeds.rb"
    session[:admin_signed_in] = true
  end

  def test_routings
    assert_routing({ method: 'get', path: 'admin/links' }, controller: 'admin/links', action: 'index')
  end
  
  def test_index
    get :index
    links = assigns :links
    refute_equal links.count(:all), 0, 'did not expect zero count'
    
    assert_template :index
    assert_response :success
  end
end