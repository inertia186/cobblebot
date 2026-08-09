require "test_helper"

class Admin::LoginTest < AcceptanceTest
  def test_basic_workflow
    Server.mock_mode(up: true, player_nicks: []) do
      ServerQuery.mock_mode(full_query: {numplayers: "0", maxplayers: "20"}) do
        admin_sign_in
        open_admin_menu
        assert page.has_content?('Admin Log Out')
        open_admin_menu
        admin_sign_out
        open_admin_menu
        assert page.has_no_content?('Admin Log Out')
      end
    end
  end

  def test_wrong
    Server.mock_mode(up: true, player_nicks: []) do
      ServerQuery.mock_mode(full_query: {numplayers: "0", maxplayers: "20"}) do
        visit '/'
        open_admin_menu
        find_link('Log In').click
        fill_in 'admin_password', with: 'WRONG'
        find_button('Login').click
        assert page.has_content?('Password incorrect.')
        open_admin_menu
        assert page.has_no_content?('Admin Log Out')
      end
    end
  end
end
