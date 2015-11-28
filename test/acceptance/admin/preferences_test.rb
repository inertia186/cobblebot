require "test_helper"

class Admin::PreferencesTest < ActionDispatch::IntegrationTest
  def setup
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
          refute page.has_content?('Internal Server Error'), 'did not expect Internal Server Error.  Check for "param is missing or the value is empty: preference" in controller response'
          assert page.has_content?('Tutorial JSON has a problem on line 1'), 'expect validation rejected.  The controller has rejected an attempt to save invalid JSON.'
          fill_in('preference.value', with: valid_json)
          click_on('Save')
        end

        ajax_sync

        refute page.has_content?('Tutorial JSON has a problem on line 1'), 'did not expect Problem on line 1.  The controller has accepted our valid JSON.'
        assert page.has_content?(valid_json), 'expect valid json in table'
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
          refute page.has_content?('Internal Server Error'), 'did not expect Internal Server Error.  Check for "param is missing or the value is empty: preference" in controller response'
          assert page.has_content?('IRC Server Port must be a valid integer.'), 'expect validation rejected.  The controller has rejected an attempt to save invalid port.'
          fill_in('preference.value', with: invalid_port_b)
          click_on('Save')
          assert page.has_content?('IRC Server Port must be a valid port number (1 to 65535).'), 'expect validation rejected.  The controller has rejected an attempt to save invalid port.'
          fill_in('preference.value', with: valid_port)
          click_on('Save')
        end

        ajax_sync

        refute page.has_content?('Tutorial JSON has a problem on line 1'), 'did not expect Problem on line 1.  The controller has accepted our valid JSON.'
        assert page.has_content?(valid_port), 'expect valid port in table'
      end
    end
  end
end
