require 'test_helper'

class ServerCallbackTest < ActiveSupport::TestCase
  # Add callback names to array to cause tests to skip in case they cannot be
  # automatically tested.
  SKIP_CALLBACKS_NAMED = []
  
  def setup
    method = :create!; eval File.read "#{Rails.root}/db/seeds.rb"
    
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
end
