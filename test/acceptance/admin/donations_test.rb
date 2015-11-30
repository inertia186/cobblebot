require "test_helper"

class Admin::DonationsTest < ActionDispatch::IntegrationTest
  def setup
    preferences(:path_to_server).update_attribute(:value, "#{Rails.root}/tmp")
  end

  def test_basic_workflow
    Server.mock_mode(up: true, player_nicks: []) do
      ServerQuery.mock_mode(full_query: {numplayers: "0", maxplayers: "20"}) do
        admin_sign_in
        admin_navigate('Donations')
        assert page.has_content?('Donations'), 'expect Donations.  We should now be on the Donations page.'
      end
    end
  end

  def test_query
    test_basic_workflow
    results_container = 'div.tab-contents > div > div > table > tbody'

    Server.mock_mode(up: true, player_nicks: []) do
      ServerQuery.mock_mode(full_query: {numplayers: "0", maxplayers: "20"}) do
        within(:css, results_container) do
          assert page.has_content?('resnullius'), 'expect resnullius in initial results'
        end

        fill_in('query', with: 'inertia')
        click_on('Search')

        within(:css, results_container) do
          assert page.has_no_content?('resnullius'), 'did not expect resnullius in inertia results'
        end
      end
    end
  end
end
