require "test_helper"

class Admin::LoginTest < ActionDispatch::IntegrationTest
  def setup
  end
  
  def test_basic_workflow
    Server.mock_mode(up: true, player_nicks: []) do
      ServerQuery.mock_mode(full_query: {numplayers: "0", maxplayers: "20"}) do
        admin_sign_in
        find_link('Admin').click
        assert page.has_content?('Admin Log Out')
        find_link('Admin').click
        admin_sign_out
        find_link('Admin').click
        refute page.has_content?('Admin Log Out')
      end
    end
  end
  
  def test_wrong
    Server.mock_mode(up: true, player_nicks: []) do
      ServerQuery.mock_mode(full_query: {numplayers: "0", maxplayers: "20"}) do
        visit '/'
        find_link('Admin').click
        find_link('Log In').click
        fill_in 'admin_password', with: 'WRONG'
        find_button('Login').click
        find_link('Admin').click
        refute page.has_content?('Admin Log Out')
        assert page.has_content?('Password incorrect.')
      end
    end
  end
end
