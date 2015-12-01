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
    assert_routing({ method: 'delete', path: 'admin/callbacks/42.js' }, controller: 'admin/callbacks', action: 'destroy', id: '42', format: 'js')
    assert_routing({ method: 'patch', path: 'admin/callbacks/42/toggle_enabled' }, controller: 'admin/callbacks', action: 'toggle_enabled', id: '42')
    assert_routing({ method: 'patch', path: 'admin/callbacks/42/toggle_enabled.js' }, controller: 'admin/callbacks', action: 'toggle_enabled', id: '42', format: 'js')
    assert_routing({ method: 'get', path: 'admin/callbacks/42/execute_command' }, controller: 'admin/callbacks', action: 'execute_command', id: '42')
    assert_routing({ method: 'get', path: 'admin/callbacks/42/execute_command.js' }, controller: 'admin/callbacks', action: 'execute_command', id: '42', format: 'js')
    assert_routing({ method: 'patch', path: 'admin/callbacks/42/reset_cooldown' }, controller: 'admin/callbacks', action: 'reset_cooldown', id: '42')
    assert_routing({ method: 'patch', path: 'admin/callbacks/42/reset_cooldown.js' }, controller: 'admin/callbacks', action: 'reset_cooldown', id: '42', format: 'js')
  end

  def test_index
    get :index
    callbacks = assigns :callbacks
    refute_equal callbacks.count, 0, 'did not expect zero count'

    assert_template :index
    assert_response :success
  end

  def test_index_all_status
    %w(ready in_cooldown enabled disabled).each do |status|
      get :index, status: status
    end
  end

  def test_show
    get :show, id: ServerCallback.first
    callback = assigns :callback

    assert_template :show
    assert_response :success
  end

  def test_new
    get :new
    callback = assigns :callback

    assert_template :new
    assert_response :success
  end

  def test_edit
    get :edit, id: ServerCallback.first
    callback = assigns :callback

    assert_template :edit
    assert_response :success
  end

  def test_reset_all_cooldown
    patch :reset_all_cooldown

    assert_template nil
    assert_redirected_to admin_server_callbacks_url
  end

  def test_create
    assert_difference -> { ServerCallback.count }, 1, 'expect different count' do
      post :create, server_callback: callback_params
    end

    assert_template nil
    assert_redirected_to admin_server_callbacks_url
  end

  def test_create_failure
    assert_no_difference -> { ServerCallback.count }, 'did not expect different count' do
      post :create, server_callback: callback_params.merge(pattern: '/(.*/i')
    end

    assert_template :new
    assert_response :success
  end

  def test_update
    callback = ServerCallback.first
    patch :update, id: callback, server_callback: callback_params

    assert_template nil
    assert_redirected_to admin_server_callbacks_url
  end

  def test_update_failure
    callback = ServerCallback.first
    patch :update, id: callback, server_callback: callback_params.merge(pattern: '/(.*/i')

    assert_template :edit
    assert_response :success
  end

  def test_toggle_enabled
    callback = ServerCallback.first
    assert_difference -> { ServerCallback.enabled.count }, -1, 'expect different count' do
      patch :toggle_enabled, id: callback
    end

    assert_template nil
    assert_redirected_to admin_server_callbacks_url
  end

  def test_toggle_enabled_js
    callback = ServerCallback.first
    assert_difference -> { ServerCallback.enabled.count }, -1, 'expect different count' do
      xhr :patch, :toggle_enabled, format: :js, id: callback
    end

    assert_template :replace_visible_callbacks
    assert_response :success
  end

  def test_execute_command
    callback = ServerCallback.first
    assert_difference -> { ServerCallback.where.not(ran_at: nil).count }, 1, 'expect different count' do
      get :execute_command, id: callback
    end

    assert_template nil
    assert_redirected_to admin_server_callbacks_url
  end

  def test_execute_command_js
    callback = ServerCallback.first
    assert_difference -> { ServerCallback.where.not(ran_at: nil).count }, 1, 'expect different count' do
      xhr :get, :execute_command, format: :js, id: callback
    end

    assert_template :replace_visible_callbacks
    assert_response :success
  end

  def test_reset_cooldown
    callback = ServerCallback.where.not(cooldown: '+0 seconds').first
    callback.update_attribute(:ran_at, Time.now)
    assert_difference -> { ServerCallback.ready.count }, 1, 'expect different count' do
      patch :reset_cooldown, id: callback
    end

    assert_template nil
    assert_redirected_to admin_server_callbacks_url
  end

  def test_reset_cooldown_js
    callback = ServerCallback.where.not(cooldown: '+0 seconds').first
    callback.update_attribute(:ran_at, Time.now)
    assert_difference -> { ServerCallback.ready.count }, 1, 'expect different count' do
      xhr :patch, :reset_cooldown, format: :js, id: callback
    end

    assert_template :replace_visible_callbacks
    assert_response :success
  end

  def test_destroy
    assert_difference -> { ServerCallback.count }, -1, 'expect different count' do
      delete :destroy, id: ServerCallback.first
    end

    assert_template nil
    assert_redirected_to admin_server_callbacks_url
  end
private
  def callback_params
    {
      name: 'name',
      pattern: '/.*/i',
      command: 'x = 1'
    }
  end
end
