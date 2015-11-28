require "test_helper"

class Admin::PlayersTest < ActionDispatch::IntegrationTest
  def setup
    preferences(:path_to_server).update_attribute(:value, "#{Rails.root}/tmp")
  end

  def test_basic_workflow
    Server.mock_mode(up: true, player_nicks: []) do
      ServerQuery.mock_mode(full_query: {numplayers: "0", maxplayers: "20"}) do
        admin_sign_in
        find_link('Admin').click
        within(:css, '#cobblebot-navbar > ul:nth-child(1) > li.dropdown.open') do
          find_link('Players').click
        end
        skip_until_pass do
          assert page.has_content?('Players'), 'expect Players.  We should now be on the Players page.'
        end
      end
    end
  end
end
