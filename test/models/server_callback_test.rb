require 'test_helper'

class ServerCallbackTest < ActiveSupport::TestCase
  # Add callback names to array to cause tests to skip in case they cannot be
  # automatically tested.
  SKIP_CALLBACKS_NAMED = []
  
  def setup
    stub_request(:get, "https://gist.github.com/inertia186/5002463").
      to_return(status: 200)
    stub_request(:get, "https://ajax.googleapis.com/ajax/services/search/news?q=florida%20man&v=1.0").
      to_return(status: 200)
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
    ServerCallback.all.find_each do |callback|
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

  def test_query
    assert ServerCallback.query('%').any?, 'expect query'
  end

  def test_valid_command
    assert ServerCallback::ServerEntry.create(command: '"%nick%"').errors.any?, 'did not expect valid callback'
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
    refute (callbacks = ServerCallback.where("pattern LIKE '%@server%'").where(help_doc_key: nil)).any?, "The following callbacks need help docs: #{callbacks.map(&:name).join(', ')}"
  end
end
