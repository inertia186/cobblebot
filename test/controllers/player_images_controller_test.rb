require 'test_helper'

class PlayerImagesControllerTest < ActionController::TestCase
  include WebStubs

  def test_routings
    assert_routing({ method: 'get', path: '/player_images/inertia186/16.png' }, controller: 'player_images', action: 'show', id: 'inertia186', size: '16', format: 'png')
  end

  def test_show
    stub_minotar('inertia186', '16', 'png') do
      get :show, params: { id: 'inertia186', size: '16', format: :png }
    end
  end

  def test_show_missing
    stub_minotar('Notch', '16', 'png') do
      get :show, params: { id: 'Notch', size: '16', format: :png }
    end
  end

  def test_show_redirected
    File.stub(:read, nil) do
      stub_minotar('Notch', '16', 'png') do
        get :show, params: { id: 'Notch', size: '16', format: :png }
      end
    end

    assert_redirected_to 'https://minotar.net/avatar/Notch/16.png'
  end
end
