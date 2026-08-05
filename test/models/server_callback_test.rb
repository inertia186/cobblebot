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

  def setup
  end

  def test_all_patterns
    ServerCallback.all.find_each do |callback|
      begin
        eval(callback.pattern, Proc.new{}.binding)
      rescue SyntaxError => e
        # :nocov:
        fail "SyntaxError while evaluating callback pattern named \"#{callback.name}\":\n#{e.inspect}"
        # :nocov:
      rescue Errno::ENOENT => e
        # skip
      end
    end
  end

  def test_all_commands
    ServerCommand.stub(:run, nil) do
      ServerCallback.all.find_each do |callback|
        begin
          stub_github do
            stub_googleapis do
              callback.execute_command("@a", "Test")
            end
          end
        rescue SyntaxError => e
          # :nocov:
          if [SKIP_CALLBACKS_NAMED].include? callback.name
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
    end
  end

  def test_all_command_as_base
    callback = ServerCallback.first.becomes(ServerCallback)

    begin
      callback.execute_command("@a", "Test")
    rescue SyntaxError => e
      # :nocov:
      if [SKIP_CALLBACKS_NAMED].include? callback.name
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
    assert ServerCallback::AnyEntry.new.player_input?, 'expect player input'
    # :nocov:
    fail 'please update test to reflect new behavior'
    # :nocov:
  rescue NotImplementedError => e
    # success
  end

  def test_callbacks_that_need_help_docs
    callbacks = ServerCallback.where("pattern LIKE '%@server%'")
    callbacks = callbacks.where(help_doc_key: nil)

    # Note, these are hidden @server patterns.
    callbacks = callbacks.where.not(name: ['Unregister', 'Set Topic', 'Predict Death'])

    refute callbacks.any?, "The following callbacks need help docs: #{callbacks.map(&:name).join(', ')}"
  end

  private

  def execute_seeded_callback(name, message)
    ServerCommand.reset_commands_executed
    ServerCallback.find_by!(name: name).execute_command('@a', message)
    refute_empty ServerCommand.commands_executed
  end
end
