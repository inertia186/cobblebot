require "test_helper"

class Admin::CallbacksTest < AcceptanceTest
  def setup
    preferences(:path_to_server).update!(value: "#{Rails.root}/tmp")
  end

  def test_navigation_and_query
    Server.mock_mode(up: true, player_nicks: []) do
      ServerQuery.mock_mode(full_query: {numplayers: "0", maxplayers: "20"}) do
        admin_sign_in
        admin_navigate('Callbacks')
        assert page.has_content?('Callbacks')

        results_container = 'div.tab-contents > div > div > table > tbody'
        within(:css, results_container) do
          assert page.has_content?('Spammy')
          assert page.has_content?('Read Mail')
        end

        fill_in('query', with: 'spammy')
        click_on('Search')

        within(:css, results_container) do
          assert page.has_content?('Spammy')
          assert page.has_no_content?('Read Mail')
        end
      end
    end
  end
end
