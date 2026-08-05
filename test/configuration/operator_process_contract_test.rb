require 'test_helper'

class OperatorProcessContractTest < ActiveSupport::TestCase
  PROCESS_COMMANDS = [
    'RAILS_ENV=production bundle exec rails server',
    'RAILS_ENV=production bundle exec rake resque:scheduler',
    'RAILS_ENV=production bundle exec rake cobblebot:workers:bootstrap',
    'TERM_CHILD=1 RAILS_ENV=production QUEUE=minecraft_watchdog bundle exec rake resque:work',
    'TERM_CHILD=1 RAILS_ENV=production QUEUE=minecraft_server_log_monitor bundle exec rake resque:work',
    'TERM_CHILD=1 RAILS_ENV=production QUEUE=irc_bot bundle exec rake resque:work'
  ].freeze

  def test_readme_documents_each_supervised_process
    readme = File.read(Rails.root.join('README.md'))

    PROCESS_COMMANDS.each do |command|
      assert_includes readme, command
    end
    assert_includes readme, 'Each long-running command must have its own process'
  end

  def test_obsolete_process_manager_surface_is_absent
    refute File.exist?(Rails.root.join('config/cobblebot.god'))

    readme = File.read(Rails.root.join('README.md'))
    refute_includes readme, 'BACKGROUND=yes'
    refute_includes readme, 'tmux send-keys'
  end
end
