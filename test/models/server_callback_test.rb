require 'test_helper'
require 'minitest/mock'

class ServerCallbackTest < ActiveSupport::TestCase
  include WebStubs

  # Add callback names to array to cause tests to skip in case they cannot be
  # automatically tested.
  SKIP_CALLBACKS_NAMED = []

  # Many of these tests require the true seeds, not fixtures.  These are marked with "IMPORTANT!"

  def test_retired_translate_callback_is_not_seeded
    refute ServerCallback.where(name: 'Translate', system: true).exists?
    refute ServerCommand.respond_to?(:say_translation)
  end

  def test_predict_rate_callback_reports_a_prediction
    truster = players(:inertia186)
    trustee = players(:resnullius)
    Reputation.create!(truster: truster, trustee: trustee, rate: 4)

    execute_seeded_callback('Predict Rate', "@server predict rate #{truster.nick} #{trustee.nick}")

    assert_includes ServerCommand.commands_executed.keys.last,
      "Predicting #{truster.nick} to rate #{trustee.nick} 4"
  end

  def test_predict_rate_callback_reports_insufficient_data
    Reputation.delete_all
    truster = players(:inertia186)
    trustee = players(:resnullius)

    execute_seeded_callback('Predict Rate', "@server predict rate #{truster.nick} #{trustee.nick}")

    assert_includes ServerCommand.commands_executed.keys.last,
      "Cannot predict what #{truster.nick} would rate #{trustee.nick}."
  end

  def test_predict_death_callback_reports_a_prediction
    player = players(:inertia186)
    players(:Dinnerbone).update!(time_since_death: 86_400)

    Server.mock_mode(player_nicks: []) do
      execute_seeded_callback('Predict Death', "@server predict death #{player.nick}")
    end

    assert_includes ServerCommand.commands_executed.keys.last,
      "Predicting #{player.nick} to die 1.00 hours after logging in."
  end

  def test_predict_death_callback_reports_insufficient_data
    Player.update_all(time_since_death: 0)
    player = players(:inertia186)

    execute_seeded_callback('Predict Death', "@server predict death #{player.nick}")

    assert_includes ServerCommand.commands_executed.keys.last,
      "Cannot predict when #{player.nick} will die."
  end

  def test_prediction_callbacks_do_not_hide_programming_errors
    assert_no_match(/rescue nil/, ServerCallback.find_by!(name: 'Predict Rate').command)
    assert_no_match(/rescue nil/, ServerCallback.find_by!(name: 'Predict Death').command)
  end

  def test_all_patterns
    valid_patterns = 0

    ServerCallback.all.find_each do |callback|
      begin
        eval(callback.pattern, Proc.new{}.binding)
        valid_patterns += 1
      rescue SyntaxError => e
        # :nocov:
        fail "SyntaxError while evaluating callback pattern named \"#{callback.name}\":\n#{e.inspect}"
        # :nocov:
      rescue Errno::ENOENT => e
        # skip
      end
    end

    assert_equal ServerCallback.count, valid_patterns
  end

  def test_all_commands
    Server.mock_mode(entity_data: [], player_nicks: []) do
      ServerCommand.stub(:run, ->(*, **) { nil }) do
        ServerCommand.stub(:detect_spam, nil) do
          ServerCommand.stub(:find_latest_chat_by_nick, nil) do
            ServerCommand.stub(:all_nicks, []) do
              ServerCallback.all.find_each do |callback|
            begin
              message = representative_message_for(callback)
              assert_match eval(callback.pattern, binding), message,
                "representative input must match #{callback.name}"
              stub_github do
                stub_googleapis do
                  callback.execute_command('inertia186', message)
                end
              end
            rescue SyntaxError => e
              # :nocov:
              if SKIP_CALLBACKS_NAMED.include? callback.name
                skip "SyntaxError while evaluating callback command named \"#{callback.name}\":\nCommand: #{callback.command}\n#{e.inspect}"
              else
                fail "SyntaxError while evaluating callback command named \"#{callback.name}\":\nCommand: #{callback.command}\n#{e.inspect}"
              end
              # :nocov:
            rescue Errno::ENOENT => e
              # skip
            end
                callback.reload
                assert callback.ran_at, 'expect callback ran'
                refute callback.error_flag?,
                  "callback command failed at runtime: #{callback.name}: " \
                  "#{callback.last_command_output.to_s.lines.first.to_s.strip}"
              end
            end
          end
        end
      end
    end
  end

  def test_all_command_as_base
    callback = ServerCallback.first.becomes(ServerCallback)

    begin
      callback.execute_command("@a", "Test")
    rescue SyntaxError => e
      # :nocov:
      if SKIP_CALLBACKS_NAMED.include? callback.name
        skip "SyntaxError while evaluating callback command named \"#{callback.name}\":\nCommand: #{callback.command}\n#{e.inspect}"
      else
        fail "SyntaxError while evaluating callback command named \"#{callback.name}\":\nCommand: #{callback.command}\n#{e.inspect}"
      end
      # :nocov:
    rescue Errno::ENOENT => e
      # skip
    end
    assert callback.ran_at, 'expect callback ran'
  end

  def test_error_flag
    callback = ServerCallback.first
    callback.update_attribute(:command, '1/0')
    callback.execute_command("@a", "Test")
    assert callback.ran?, 'expect callback ran'
    assert callback.error_flag?, 'expect callback to have error flag'
  end

  def test_only_enabled
    refute_equal ServerCallback.enabled.count, 0, 'expect non-zero results'
  end

  def test_only_disabled
    assert_equal ServerCallback.enabled(false).count,  0, 'expect zero results'
  end

  def test_ready?
    callback = ServerCallback.find_by_name('Spammy')
    callback.execute_command("@a", "Test")
    assert callback.ready?, 'expect ready'
  end

  def test_not_ready
    assert ServerCallback.ready(false).none?, 'did not expect ready'
  end

  def test_error_flagged
    assert ServerCallback.error_flagged.none?, 'expect error falgged'
  end

  def test_not_error_flagged
    assert ServerCallback.error_flagged(false).any?, 'did not expect error flagged'
  end

  def test_needs_prettification
    assert ServerCallback.needs_prettification.any?, 'expect needs prettification'
  end

  def test_not_needs_prettification
    assert ServerCallback.needs_prettification(false).none?, 'did not expect needs prettification'
  end

  def test_prettify_highlights_ruby_locally_and_escapes_html
    callback = ServerCallback.first
    callback.update!(pattern: '/<script>/')

    callback.prettify(:pattern)

    assert_includes callback.reload.pretty_pattern, '<pre class="highlight"><code>'
    assert_includes callback.pretty_pattern, '&lt;script&gt;'
    refute_includes callback.pretty_pattern, '<script>'
  end

  def test_has_help_docs
    assert (callbacks = ServerCallback.has_help_docs).any?, 'expect callbacks with help docs'
    assert callbacks.map(&:help_doc_key).uniq.size > 0, 'expect callbacks with help docs'
  end

  def test_not_has_help_docs
    assert (callbacks = ServerCallback.has_help_docs(false)).any?, 'expect callbacks without help docs'
    assert (keys = callbacks.map(&:help_doc_key).uniq).size == 1 && keys == [nil], 'expect callbacks without help docs'
  end

  def test_query
    assert ServerCallback.query('%').any?, 'expect query'
  end

  def test_valid_command
    callback = ServerCallback::ServerEntry.new(
      name: 'Invalid Nick Reference',
      pattern: '/invalid nick reference/',
      command: '"%nick%"'
    )

    refute callback.valid?, 'did not expect valid callback'
    assert_equal [
      'cannot reference %nick% in a Server Callback/Server Entry callback.  Try %1% if you intend to capture the nick yourself.'
    ], callback.errors[:command]
  end

  def test_invalid_command_syntax_records_string_errors
    callback = ServerCallback::PlayerCommand.new(
      name: 'Invalid Command Syntax',
      pattern: '/invalid command syntax/',
      command: 'if'
    )

    refute callback.valid?, 'did not expect valid callback'
    assert_equal ['has syntax error(s)'], callback.errors[:command]
    assert callback.errors[:base].all? { |message| message.is_a?(String) }
    assert callback.errors[:base].all?(&:present?)
  end

  def test_player_input?
    assert_raises(NotImplementedError) do
      ServerCallback::AnyEntry.new.player_input?
    end
  end

  def test_callbacks_that_need_help_docs
    callbacks = ServerCallback.where("pattern LIKE '%@server%'")
    callbacks = callbacks.where(help_doc_key: nil)

    # Note, these are hidden @server patterns.
    callbacks = callbacks.where.not(name: ['Unregister', 'Set Topic', 'Predict Death'])

    refute callbacks.any?, "The following callbacks need help docs: #{callbacks.map(&:name).join(', ')}"
  end

  private

  def representative_message_for(callback)
    case callback.name
    when 'Player Authenticated', 'Message of the Day', 'Current Topic'
      'UUID of player inertia186 is d6edf996-6182-4d58-ac1b-4ca0321fb748'
    when 'Spammy', 'Latest Player Chat'
      'ordinary player chat'
    when 'Autolink'
      'http://github.com/inertia186/cobblebot'
    when 'IRC Reply'
      '@irc hello'
    when 'Send Mail'
      '@Dinnerbone hello'
    when 'Check Version'
      '@server version'
    when 'Help ...'
      '@server help'
    when 'lmgtfy'
      '@server lmgtfy rails'
    when 'Message of the Day (self)'
      '@server motd'
    when 'Sync Me'
      '@server syncme'
    when 'Sound Check'
      '@server soundcheck'
    when 'Player Check'
      '@server playercheck inertia186'
    when 'Slap'
      '@server slap Dinnerbone'
    when 'Add Tip'
      '@server addtip useful tip'
    when 'Reply Tip'
      '@server replytip useful tip'
    when 'Random Tip'
      '@server tip'
    when 'Tip Info'
      '@server tips'
    when 'Rules'
      '@server rules'
    when 'Tutorial'
      '@server tutorial'
    when 'FAQ'
      '@server faq'
    when 'Toggle Sounds'
      '@server togglesounds'
    when 'Register'
      '@server register'
    when 'Unregister'
      '@server unregister'
    when 'Origin'
      '@server origin inertia186'
    when 'Read Mail'
      '@server mail'
    when 'Topic'
      '@server topic'
    when 'Set Topic'
      '@server topic test topic'
    when 'Rate'
      '@server rate Dinnerbone 1'
    when 'Vote Kick'
      '@server votekick Dinnerbone'
    when 'Get Trust'
      '@server gettrust inertia186 Dinnerbone'
    when 'Gametick'
      '@server gametick'
    when 'Behind'
      'Running 100ms behind, skipping 2 tick'
    when 'Autosync'
      'inertia186 moved wrongly!'
    when 'Latest Player IP'
      'inertia186[/127.0.0.1:63640] logged in with entity id 1 at (1.0, 2.0, 3.0)'
    when 'Player Logged Out'
      'inertia186 lost connection'
    when 'Cleaned Up Stats'
      'Invalid statistic in ./world/stats/d6edf996-6182-4d58-ac1b-4ca0321fb748.json: invalid stat'
    when 'Update Last Nick'
      'inertia186 formerly known as OldNick joined the game'
    when 'Calc'
      '=1+1'
    when 'Predict Rate'
      '@server predict rate inertia186 Dinnerbone'
    when 'Predict Death'
      '@server predict death inertia186'
    when 'Last PVP'
      '@server lastpvp'
    when 'Number Guess'
      '@server numberguess'
    when 'Donations'
      '@server donations'
    when 'Florida Man'
      '@server floridaman'
    when 'Grammar Nazi #001'
      'could of'
    when 'Dijon?'
      'an expensive test'
    when 'Captain Obvious'
      'time itself is time'
    when 'CAPS'
      'THIS IS ALL CAPS'
    when 'Search Replace'
      '%s/axe/sword/'
    when 'Predict'
      'com.mojang.authlib.GameProfile@1[id=<null>,name=inertia186,properties={},legacy=false] (/127.0.0.1:1) lost connection: Disconnected'
    when 'Slain'
      'inertia186 was slain by Dinnerbone'
    when 'Shot'
      'inertia186 was shot by Dinnerbone'
    when 'Killed'
      'inertia186 was killed by Dinnerbone'
    when 'Thorns'
      'inertia186 was killed trying to hurt Dinnerbone'
    when 'Burnt'
      'inertia186 was burnt to a crisp'
    when 'Lava Swim'
      'inertia186 tried to swim in lava'
    when 'Sploded to Death'
      'inertia186 was blown up by Dinnerbone'
    when 'Pricked'
      'inertia186 pricked to death'
    when 'Overpowered'
      '[Overpowered]'
    when 'The Beginning'
      'The Beginning!'
    when 'boo'
      'halloween'
    when 'SEGA'
      'blast processing'
    when 'Navi'
      '!!!'
    when 'The More You Know'
      'tmyk'
    when 'Bueller?'
      'anyone?'
    when 'Facepalm'
      'inertia186 facepalms'
    when 'Killed Using Magic'
      'inertia186 was killed by Dinnerbone using magic'
    when 'Fell Out of the World'
      'inertia186 fell out of the world'
    when 'Knocked Into the Void'
      'inertia186 was knocked into the void'
    when 'Fell'
      'inertia186 fell from a high place'
    when 'Doomed to Fall'
      'inertia186 was doomed to fall'
    when 'Hit the Ground Too Hard'
      'inertia186 hit the ground too hard'
    when 'Starved to Death'
      'inertia186 starved to death'
    when 'Withered Away'
      'inertia186 withered away'
    when 'Killed by Witch'
      'inertia186 killed by Witch'
    when 'Burned'
      'inertia186 burned to death'
    when 'Anvil Death'
      'inertia186 was squashed by an anvil'
    when 'Bat Death?'
      'inertia186 was slain by Bat'
    when 'Fireballed to Death'
      'inertia186 was fireballed'
    when 'Just Died'
      'inertia186 died'
    when 'Killer Bunny'
      'inertia186 was slain by The Killer Bunny'
    when 'Kinetic Energy'
      'inertia186 experienced kinetic energy'
    when 'Flying Kick'
      'inertia186 was kicked for floating too long'
    when 'Idle Kick'
      'You have been idle for too long'
    when 'Another Client'
      'You logged in from another location'
    else
      callback.name
    end
  end

  def execute_seeded_callback(name, message)
    ServerCommand.reset_commands_executed
    ServerCallback.find_by!(name: name).execute_command('@a', message)
    refute_empty ServerCommand.commands_executed
  end
end
