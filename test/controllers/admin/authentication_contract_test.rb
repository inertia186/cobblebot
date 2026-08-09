require 'test_helper'

class Admin::AuthenticationContractTest < ActionDispatch::IntegrationTest
  def test_callbacks_reject_every_unauthenticated_read_and_mutation
    callback = ServerCallback.first
    original = callback.attributes.slice(
      'enabled', 'last_match', 'last_command_output', 'ran_at'
    )
    original_count = ServerCallback.count
    command_calls = 0

    assert_requires_admin :get, admin_server_callbacks_path
    assert_requires_admin :get, new_admin_server_callback_path
    assert_requires_admin :get, admin_server_callback_path(callback)
    assert_requires_admin :get, edit_admin_server_callback_path(callback)
    assert_requires_admin :get,
      gist_callback_admin_server_callback_path(callback)
    assert_requires_admin :post, admin_server_callbacks_path,
      params: {server_callback: {name: 'Unauthorized callback'}}
    assert_requires_admin :patch, admin_server_callback_path(callback),
      params: {server_callback: {name: 'Unauthorized update'}}
    assert_requires_admin :delete, admin_server_callback_path(callback)
    assert_requires_admin :patch, reset_all_cooldown_admin_server_callbacks_path
    assert_requires_admin :patch,
      toggle_enabled_admin_server_callback_path(callback)
    ServerCommand.stub(:eval_command, ->(*) { command_calls += 1 }) do
      assert_requires_admin :patch,
        execute_command_admin_server_callback_path(callback)
    end
    assert_requires_admin :patch,
      reset_cooldown_admin_server_callback_path(callback)

    assert_equal 0, command_calls
    assert_equal original_count, ServerCallback.count
    assert_equal original, callback.reload.attributes.slice(*original.keys)
  end

  def test_donations_reject_every_unauthenticated_read_and_mutation
    donation = messages(:donation_from_resnullius)
    original_body = donation.body
    original_count = Message::Donation.count

    assert_requires_admin :get, admin_message_donations_path
    assert_requires_admin :get, new_admin_message_donation_path
    assert_requires_admin :get, admin_message_donation_path(donation)
    assert_requires_admin :get, edit_admin_message_donation_path(donation)
    assert_requires_admin :post, admin_message_donations_path,
      params: {message_donation: {body: '$999 unauthorized'}}
    assert_requires_admin :patch, admin_message_donation_path(donation),
      params: {message_donation: {body: '$999 unauthorized'}}
    assert_requires_admin :delete, admin_message_donation_path(donation)

    assert_equal original_count, Message::Donation.count
    assert_equal original_body, donation.reload.body
  end

  def test_links_reject_unauthenticated_reads_and_deletion
    link = links(:cobblebot)
    original_count = Link.count

    assert_requires_admin :get, admin_links_path
    assert_requires_admin :get, admin_link_path(link)
    assert_requires_admin :delete, admin_link_path(link)

    assert_equal original_count, Link.count
    assert Link.exists?(link.id)
  end

  def test_messages_reject_unauthenticated_reads
    message = messages(:nether_horses)
    original_count = Message.count

    assert_requires_admin :get, admin_messages_path
    assert_requires_admin :get, admin_message_path(message)
    assert_requires_admin :delete, admin_message_path(message)

    assert_equal original_count, Message.count
    assert Message.exists?(message.id)
  end

  def test_players_reject_unauthenticated_reads_and_mutations
    player = players(:inertia186)
    original_autolink = player.may_autolink
    original_count = Player.count

    assert_requires_admin :get, admin_players_path
    assert_requires_admin :get, admin_player_path(player)
    assert_requires_admin :patch, toggle_may_autolink_admin_player_path(player)
    assert_requires_admin :delete, admin_player_path(player)

    assert_equal original_count, Player.count
    assert_equal original_autolink, player.reload.may_autolink
  end

  def test_preferences_reject_unauthenticated_reads_and_updates
    preference = preferences(:motd)
    original_value = preference.value

    assert_requires_admin :get, admin_preferences_path
    assert_requires_admin :get, edit_cell_admin_preferences_path
    assert_requires_admin :patch, admin_preference_path(preference.key),
      params: {preference: {value: 'unauthorized change'}}

    assert_equal original_value, preference.reload.value
  end

private
  def assert_requires_admin(method, path, params: nil)
    public_send(method, path, params: params)

    assert_redirected_to new_admin_session_url
  end
end
