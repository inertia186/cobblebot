require 'test_helper'
require 'rake'

class DocumentationContractTest < ActiveSupport::TestCase
  def test_supported_runtime_matches_the_locked_framework
    assert_match(/Ruby 3\.3\.12.*Rails\s+8\.1\.3\.1/m, readme)
    assert_includes readme, 'Rails 8.1 configuration defaults'
  end

  def test_installation_requires_an_operator_supplied_admin_secret
    assert_includes readme, Preference::WEB_ADMIN_PASSWORD_ENV
    refute_includes readme, '123456'
    refute_includes seeds, '123456'
    refute_includes seeds, "value: 'secret'"
  end

  def test_reputation_recovery_uses_the_available_import_task
    ApplicationTaskTestSupport.load

    assert Rake::Task.task_defined?('cobblebot:import:reputations')
    assert_includes readme, 'cobblebot:import:reputations'
    refute_includes readme, 'cobblebot:reputations:mutes'
  end

  def test_worker_atomicity_and_test_redis_are_documented
    assert_match(/atomic Redis Lua\s+operation/, readme)
    assert_match(/pop a job and publish their working payload\s+in one Lua operation/, readme)
    assert_match(/do\s+not use lease keys, TTLs, or cleanup locks/, readme)
    assert_includes readme, 'test environment requires PostgreSQL and Redis'
    assert_match(/Configure that check as\s+required/, readme)
  end

  def test_irc_operator_configuration_uses_authenticated_identities
    assert_includes readme, 'irc:<account>'
    assert_includes readme, 'twitch:<user-id>'
    assert_match(/Nicknames are\s+not credentials/, readme)
    assert_match(/denies every privileged command/, readme)
  end

private
  def readme
    @readme ||= Rails.root.join('README.md').read
  end

  def seeds
    @seeds ||= Rails.root.join('db/seeds.rb').read
  end
end
