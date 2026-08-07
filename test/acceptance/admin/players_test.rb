require "test_helper"

class Admin::PlayersTest < AcceptanceTest
  def setup
    preferences(:path_to_server).update!(value: "#{Rails.root}/tmp")
  end

  def test_basic_workflow
    Server.mock_mode(up: true, player_nicks: []) do
      ServerQuery.mock_mode(full_query: {numplayers: "0", maxplayers: "20"}) do
        admin_sign_in
        admin_navigate('Players')
        assert page.has_content?('Players'), 'expect Players.  We should now be on the Players page.'
      end
    end
  end

  def test_query
    test_basic_workflow
    results_container = 'div.tab-contents > div > div > table > tbody'

    Server.mock_mode(up: true, player_nicks: []) do
      ServerQuery.mock_mode(full_query: {numplayers: "0", maxplayers: "20"}) do
        within(:css, results_container) do
          assert page.has_content?('inertia186'), 'expect inertia186 in initial results'
          assert page.has_content?('Dinnerbone'), 'expect Dinnerbone in initial results'
        end

        fill_in('query', with: 'inertia')
        click_on('Search')
        assert_selector 'input#query[value="inertia"]'

        within(:css, results_container) do
          assert page.has_content?('inertia186'), 'expect inertia186 in inertia results'
          assert page.has_no_content?('Dinnerbone'), 'did not expect Dinnerbone in inertia results'
        end
      end
    end
  end
end
