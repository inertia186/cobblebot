require "test_helper"

class Admin::PreferencesTest < ActionDispatch::IntegrationTest
  def setup
    preferences(:path_to_server).update_attribute(:value, "#{Rails.root}/tmp")

  end

  def test_basic_workflow
    valid_json = '{"valid": "json"}'
    invalid_json = '-- {INVALID JSON!} --'

    Server.mock_mode(up: true, player_nicks: []) do
      ServerQuery.mock_mode(full_query: {numplayers: "0", maxplayers: "20"}) do
        admin_sign_in
        assert page.has_content?('Preferences'), 'expect Preferences.  We should now be on the Preferences page.'

        within(:css, '#tutorial_json') do
          click_on('Edit')
          fill_in('preference.value', with: invalid_json)
          click_on('Save')
          assert page.has_no_content?('Internal Server Error'), 'did not expect Internal Server Error.  Check for "param is missing or the value is empty: preference" in controller response'
          assert page.has_content?('Tutorial JSON has a problem on line 1'), 'expect validation rejected.  The controller has rejected an attempt to save invalid JSON.'
          fill_in('preference.value', with: valid_json)
          click_on('Save')
        end

        ajax_sync

        assert page.has_no_content?('Tutorial JSON has a problem on line 1'), 'did not expect Problem on line 1.  The controller has accepted our valid JSON.'
        assert page.has_content?(valid_json), 'expect valid json in table'
      end
    end
  end

  def test_system_preferences
    Server.mock_mode(up: true, player_nicks: []) do
      ServerQuery.mock_mode(full_query: {numplayers: "0", maxplayers: "20"}) do
        admin_sign_in
        assert page.has_content?('Preferences'), 'expect Preferences.  We should now be on the Preferences page.'
        visit('/admin/preferences?system=true')
        assert page.has_content?('Preferences'), 'expect Preferences.  We should still be on the Preferences page.'
        ajax_sync
        Preference.system.find_each do |preference|
          assert page.has_content?(preference.key), "expect #{preference.key}.  We should see all system preferences."
        end
      end
    end
  end

  def test_edit_path_to_server
    valid_path = preferences(:path_to_server).value
    invalid_path = '/path/that/does/not/exist'

    Server.mock_mode(up: true, player_nicks: []) do
      ServerQuery.mock_mode(full_query: {numplayers: "0", maxplayers: "20"}) do
        admin_sign_in
        assert page.has_content?('Preferences'), 'expect Preferences.  We should now be on the Preferences page.'

        within(:css, '#path_to_server') do
          click_on('Edit')
          fill_in('preference.value', with: invalid_path)
          click_on('Save')
          assert page.has_no_content?('Internal Server Error'), 'did not expect Internal Server Error.  Check for "param is missing or the value is empty: preference" in controller response'
          assert page.has_content?('Path to Server does not exist.'), 'expect validation rejected.  The controller has rejected an attempt to save invalid path.'
          fill_in('preference.value', with: valid_path)
          click_on('Save')
        end

        ajax_sync

        assert page.has_no_content?('Tutorial JSON has a problem on line 1'), 'did not expect Problem on line 1.  The controller has accepted our valid JSON.'
        assert page.has_content?(valid_path), 'expect valid path to server in table'
      end
    end
  end

  def test_edit_irc_server_port
    valid_port = '6667'
    invalid_port_a = 'abc'
    invalid_port_b = '-99'

    Server.mock_mode(up: true, player_nicks: []) do
      ServerQuery.mock_mode(full_query: {numplayers: "0", maxplayers: "20"}) do
        admin_sign_in
        assert page.has_content?('Preferences'), 'expect Preferences.  We should now be on the Preferences page.'

        within(:css, '#irc_server_port') do
          click_on('Edit')
          fill_in('preference.value', with: invalid_port_a)
          click_on('Save')
          assert page.has_no_content?('Internal Server Error'), 'did not expect Internal Server Error.  Check for "param is missing or the value is empty: preference" in controller response'
          assert page.has_content?('IRC Server Port must be a valid integer.'), 'expect validation rejected.  The controller has rejected an attempt to save invalid port.'
          fill_in('preference.value', with: invalid_port_b)
          click_on('Save')
          assert page.has_content?('IRC Server Port must be a valid port number (1 to 65535).'), 'expect validation rejected.  The controller has rejected an attempt to save invalid port.'
          fill_in('preference.value', with: valid_port)
          click_on('Save')
        end

        ajax_sync

        assert page.has_no_content?('Tutorial JSON has a problem on line 1'), 'did not expect Problem on line 1.  The controller has accepted our valid JSON.'
        assert page.has_content?(valid_port), 'expect valid irc server port in table'
      end
    end
  end

  def test_slack_group
    Preference.slack_api_key = "ID12345678"
    stub_auth_test(Preference.slack_api_key) do
      stub_groups_list(Preference.slack_api_key) do
        Server.mock_mode(up: true, player_nicks: []) do
          ServerQuery.mock_mode(full_query: {numplayers: "0", maxplayers: "20"}) do
            admin_sign_in
            # cheaty way to prime the pump
            visit '/admin/preferences/slack_group_element'
            assert page.has_no_content?('Please configure Slack and restart CobbleBot.'), 'did not expect warning about configuring Slack.'
            visit '/admin/preferences'
            ajax_sync
            assert page.has_content?('Preferences'), 'expect Preferences.  We should now be on the Preferences page.'

            within(:css, '#slack_group') do
              click_on('Edit')
              within(:css, 'slack-group-element') do
                ajax_sync(tries: 2, wait_for: 15, message: 'AngularJS is taking a while to handle slack group list directive.')
                select('cobblebot', from: 'preference.value')
              end
              click_on('Save')
              assert page.has_no_content?('Internal Server Error'), 'did not expect Internal Server Error.  Check for "param is missing or the value is empty: preference" in controller response'
              ajax_sync
              assert page.has_content?('G12345678'), 'expect valid slack group in table'
            end
          end
        end
      end
    end
  end
end
