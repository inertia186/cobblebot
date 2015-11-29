require "test_helper"

class PlayersTest < ActionDispatch::IntegrationTest
  def setup
  end

  def test_basic_workflow
    Server.mock_mode(up: true, player_nicks: []) do
      ServerQuery.mock_mode(full_query: {numplayers: "0", maxplayers: "20"}) do
        visit '/players'

        assert page.has_no_content?('Searching ...'), 'did not expect "Searching ..." text showing'
      end
    end
  end

  # def test_basic_json
  #   Server.mock_mode(up: true) do
  #     visit '/players.json'
  #     assert_equal 'application/json; charset=utf-8', page.response_headers['Content-Type']
  #     refute_match '[]', page.source
  #   end
  # end
end
