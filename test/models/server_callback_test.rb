require 'test_helper'

class ServerCallbackTest < ActiveSupport::TestCase
  def setup
    sym = :create!; eval File.read "#{Rails.root}/db/seeds.rb"
  end

  def test_all_patterns
    ServerCallback.all.find_each do |callback|
      begin
        eval(callback.pattern)
      rescue SyntaxError => e
        fail "SyntaxError while evaluating callback pattern named \"#{callback.name}\":\n#{e.inspect}"
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
        if ['Search Replace'].include? callback.name 
          skip 'Need to revisit these.'
        else
          fail "SyntaxError while evaluating callback command named \"#{callback.name}\":\nCommand: #{callback.command}\n#{e.inspect}"
        end
      rescue Errno::ENOENT => e
        # skip
      end
      assert callback.ran_at, 'expect callback ran'
    end
  end

  def test_only_enabled
    assert ServerCallback.enabled.count > 0, 'expect non-zero results'
  end

  def test_only_enabled
    assert_equal ServerCallback.enabled(false).count,  0, 'expect zero results'
  end
end
