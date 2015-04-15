require 'test_helper'

class Admin::CallbacksControllerTest < ActionController::TestCase
  def setup
    session[:admin_signed_in] = true
  end

  def test_routings
    assert_routing({ method: 'get', path: 'admin/callbacks' }, controller: 'admin/callbacks', action: 'index')
    assert_routing({ method: 'patch', path: 'admin/callbacks/reset_all_cooldown' }, controller: 'admin/callbacks', action: 'reset_all_cooldown')
    assert_routing({ method: 'get', path: 'admin/callbacks/42' }, controller: 'admin/callbacks', action: 'show', id: '42')
    assert_routing({ method: 'get', path: 'admin/callbacks/new' }, controller: 'admin/callbacks', action: 'new')
    assert_routing({ method: 'get', path: 'admin/callbacks/42/edit' }, controller: 'admin/callbacks', action: 'edit', id: '42')
    assert_routing({ method: 'post', path: 'admin/callbacks' }, controller: 'admin/callbacks', action: 'create')
    assert_routing({ method: 'patch', path: 'admin/callbacks/42' }, controller: 'admin/callbacks', action: 'update', id: '42')
    assert_routing({ method: 'delete', path: 'admin/callbacks/42' }, controller: 'admin/callbacks', action: 'destroy', id: '42')
    assert_routing({ method: 'delete', path: 'admin/callbacks/42.json' }, controller: 'admin/callbacks', action: 'destroy', id: '42', format: 'json')
    assert_routing({ method: 'patch', path: 'admin/callbacks/42/toggle_enabled' }, controller: 'admin/callbacks', action: 'toggle_enabled', id: '42')
    assert_routing({ method: 'patch', path: 'admin/callbacks/42/toggle_enabled.json' }, controller: 'admin/callbacks', action: 'toggle_enabled', id: '42', format: 'json')
    assert_routing({ method: 'get', path: 'admin/callbacks/42/execute_command' }, controller: 'admin/callbacks', action: 'execute_command', id: '42')
    assert_routing({ method: 'get', path: 'admin/callbacks/42/execute_command.json' }, controller: 'admin/callbacks', action: 'execute_command', id: '42', format: 'json')
    assert_routing({ method: 'patch', path: 'admin/callbacks/42/reset_cooldown' }, controller: 'admin/callbacks', action: 'reset_cooldown', id: '42')
    assert_routing({ method: 'patch', path: 'admin/callbacks/42/reset_cooldown.json' }, controller: 'admin/callbacks', action: 'reset_cooldown', id: '42', format: 'json')
  end

  def test_index
    get :index
    callbacks = assigns :callbacks
    refute_equal callbacks.count, 0, 'did not expect zero count'
    
    assert_template :index
    assert_response :success
  end
  
  def test_reset_all_cooldown
    patch :reset_all_cooldown

    assert_template nil
    assert_redirected_to admin_server_callbacks_url
  end
  
  def test_create
    callback_params = {
      name: 'name',
      pattern: '/.*/i',
      command: 'x = 1'
    }
    
    assert_difference -> { ServerCallback.count }, 1, 'expect different count' do
      post :create, server_callback: callback_params
    end

    assert_template nil
    assert_redirected_to admin_server_callbacks_url
  end

  def test_create_with_errors
    callback_params = {
      name: 'name',
      pattern: '/(.*/i', # intentional typo
      command: 'x = 1'
    }
    
    assert_no_difference -> { ServerCallback.count }, 'did not expect different count' do
      post :create, server_callback: callback_params
    end

    assert_template :new
    assert_response :success
  end

  def test_destroy
    assert_difference -> { ServerCallback.count }, -1, 'expect different count' do
      delete :destroy, id: ServerCallback.first
    end

    assert_template nil
    assert_redirected_to admin_server_callbacks_url
  end
end
