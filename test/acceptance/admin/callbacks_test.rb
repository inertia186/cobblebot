require "test_helper"

class Admin::CallbacksTest < ActionDispatch::IntegrationTest
  def setup
    preferences(:path_to_server).update_attribute(:value, "#{Rails.root}/tmp")
  end

  def test_basic_workflow
    Server.mock_mode(up: true, player_nicks: []) do
      ServerQuery.mock_mode(full_query: {numplayers: "0", maxplayers: "20"}) do
        admin_sign_in
        admin_navigate('Callbacks')
        assert page.has_content?('Callbacks'), 'expect Callbacks.  We should now be on the Callbacks page.'
      end
    end
  end

  def test_query
    test_basic_workflow
    results_container = 'div.tab-contents > div > div > table > tbody'

    Server.mock_mode(up: true, player_nicks: []) do
      ServerQuery.mock_mode(full_query: {numplayers: "0", maxplayers: "20"}) do
        within(:css, results_container) do
          assert page.has_content?('Spammy'), 'expect Spammy in initial results'
          assert page.has_content?('Read Mail'), 'expect Read Mail in initial results'
        end

        fill_in('query', with: 'spammy')
        click_on('Search')

        within(:css, results_container) do
          assert page.has_content?('Spammy'), 'expect Spammy in spammy results'
          assert page.has_no_content?('Read Mail'), 'expect Read Mail in spammy results'
        end
      end
    end
  end
end
