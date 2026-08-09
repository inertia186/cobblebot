require "test_helper"

class Admin::PlayersTest < AcceptanceTest
  def setup
    preferences(:path_to_server).update!(value: "#{Rails.root}/tmp")
  end

  def test_navigation_and_query
    Server.mock_mode(up: true, player_nicks: []) do
      ServerQuery.mock_mode(full_query: {numplayers: "0", maxplayers: "20"}) do
        admin_sign_in
        admin_navigate('Players')
        assert page.has_content?('Players')

        results_container = 'div.tab-contents > div > div > table > tbody'
        within(:css, results_container) do
          assert page.has_content?('inertia186')
          assert page.has_content?('Dinnerbone')
        end

        fill_in('query', with: 'inertia')
        click_on('Search')
        assert_selector 'input#query[value="inertia"]'

        within(:css, results_container) do
          assert page.has_content?('inertia186')
          assert page.has_no_content?('Dinnerbone')
        end
      end
    end
  end
end
