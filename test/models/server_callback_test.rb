require 'test_helper'

class ServerCallbackTest < ActiveSupport::TestCase
  # Add callback names to array to cause tests to skip in case they cannot be
  # automatically tested.
  SKIP_CALLBACKS_NAMED = []
  
  def setup
    sym = :create!; eval File.read "#{Rails.root}/db/seeds.rb"
  end

  def test_all_patterns
    ServerCallback.all.find_each do |callback|
      begin
        eval(callback.pattern)
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
        MinecraftServerLogHandler.execute_command(callback, "@a", "Test")
      rescue SyntaxError => e
        if [SKIP_CALLBACKS_NAMED].include? callback.name 
          skip "SyntaxError while evaluating callback command named \"#{callback.name}\":\nCommand: #{callback.command}\n#{e.inspect}"
        else
          # :nocov:
          fail "SyntaxError while evaluating callback command named \"#{callback.name}\":\nCommand: #{callback.command}\n#{e.inspect}"
          # :nocov:
        end
      rescue Errno::ENOENT => e
        # skip
      end
      assert callback.ran_at, 'expect callback ran'
    end
  end

  def test_error_flag
    callback = ServerCallback.first
    callback.update_attribute(:command, '1/0')
    MinecraftServerLogHandler.execute_command(callback, "@a", "Test")
    assert callback.ran?, 'expect callback ran'
    assert callback.error_flag?, 'expect callback to have error flag'
  end

  def test_only_enabled
    refute_equal ServerCallback.enabled.count, 0, 'expect non-zero results'
  end

  def test_only_disabled
    assert_equal ServerCallback.enabled(false).count,  0, 'expect zero results'
  end
end
