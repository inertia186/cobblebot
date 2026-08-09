require "test_helper"

class PlayersTest < AcceptanceTest
  def setup
    preferences(:path_to_server).update!(value: Rails.root.join('tmp').to_s)
    ServerProperties.reset_vars
  end

  def test_basic_workflow
    player = players(:inertia186)

    Server.mock_mode(up: true, player_nicks: [player.nick]) do
      ServerQuery.mock_mode(full_query: {numplayers: "1", maxplayers: "20"}) do
        visit '/players'

        assert page.has_no_content?('Searching ...'), 'did not expect "Searching ..." text showing'
        assert_selector 'table > tbody > tr', minimum: 2
        assert page.has_content?(player.nick), 'expected representative player data'
      end
    end
  end
end
