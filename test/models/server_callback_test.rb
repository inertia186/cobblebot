require 'test_helper'
include ApplicationHelper

class ServerCallbackTest < ActiveSupport::TestCase
  def setup
    load "#{Rails.root}/db/seeds.rb"
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
        fail "SyntaxError while evaluating callback command named \"#{callback.name}\":\nCommand: #{callback.command}\n#{e.inspect}"
      rescue Errno::ENOENT => e
        # skip
      end
    end
  end
end

module ApplicationHelper
  def server_properties_path
    Preference.path_to_server
  end
end