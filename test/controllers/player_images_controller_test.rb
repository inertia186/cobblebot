require 'test_helper'

class PlayerImagesControllerTest < ActionController::TestCase
  include WebStubs

  def test_routings
    assert_routing({ method: 'get', path: '/player_images/inertia186/16.png' }, controller: 'player_images', action: 'show', id: 'inertia186', size: '16', format: 'png')
  end

  def test_show
    stub_minotar('inertia186', '16', 'png') do
      get :show, id: 'inertia186', size: '16', format: :png
    end
  end

  def test_show_missing
    stub_minotar('Notch', '16', 'png') do
      get :show, id: 'Notch', size: '16', format: :png
    end
  end

  def test_show_redirected
    stub_minotar('jeb_', '16', 'png') do
      get :show, id: 'jeb_', size: '16', format: :png
    end
  end
end
