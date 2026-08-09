require "test_helper"

class Admin::LinksTest < AcceptanceTest
  include WebStubs

  def setup
    preferences(:path_to_server).update!(value: "#{Rails.root}/tmp")
  end

  def test_navigation_and_query
    Server.mock_mode(up: true, player_nicks: []) do
      ServerQuery.mock_mode(full_query: {numplayers: "0", maxplayers: "20"}) do
        stub_mit do
          stub_github do
            admin_sign_in
            admin_navigate('Links')
            assert page.has_content?('Links')

            results_container = 'div.tab-contents > div > div > table > tbody'
            within(:css, results_container) do
              assert page.has_content?('inertia186/cobblebot - GitHub')
              assert page.has_content?('MIT - Massachusetts Institute of Technology')
            end

            fill_in('query', with: 'inertia')
            click_on('Search')
            assert_selector 'input#query[value="inertia"]'

            within(:css, results_container) do
              assert page.has_content?('inertia186/cobblebot - GitHub')
              assert page.has_no_content?('MIT - Massachusetts Institute of Technology')
            end
          end
        end
      end
    end
  end
end
