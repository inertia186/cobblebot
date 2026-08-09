require "test_helper"

class Admin::DonationsTest < AcceptanceTest
  def setup
    preferences(:path_to_server).update!(value: "#{Rails.root}/tmp")
  end

  def test_navigation_and_query
    Server.mock_mode(up: true, player_nicks: []) do
      ServerQuery.mock_mode(full_query: {numplayers: "0", maxplayers: "20"}) do
        admin_sign_in
        admin_navigate('Donations')
        assert page.has_content?('Donations')

        results_container = 'div.tab-contents > div > div > table > tbody'
        within(:css, results_container) do
          assert page.has_content?('resnullius')
        end

        fill_in('query', with: 'inertia')
        click_on('Search')
        assert_selector 'input#query[value="inertia"]'

        within(:css, results_container) do
          assert page.has_no_content?('resnullius')
        end
      end
    end
  end
end
