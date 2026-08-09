require 'test_helper'

class CiWorkflowTest < ActiveSupport::TestCase
  def test_ci_provides_both_required_stateful_services
    assert_includes workflow, 'image: postgres:17-alpine'
    assert_includes workflow, 'image: redis:8-alpine'
    assert_includes workflow, 'COBBLEBOT_REDIS_URL:'
    assert_includes workflow, 'DATABASE_URL:'
  end

  def test_ci_runs_concurrency_diagnostics_and_the_coverage_gate
    assert_includes workflow, 'test/models/server_callback_concurrency_test.rb'
    assert_includes workflow,
      'test/services/server_callback_execution_lock_test.rb'
    assert_includes workflow, 'test/integration/resque_runtime_test.rb'
    assert_includes workflow, 'Run complete parallel suite'
    assert_includes workflow, 'Run complete serial coverage gate'
    assert_includes workflow, 'bundle exec rake cobblebot:test:coverage'
  end

  def test_third_party_actions_are_pinned_to_full_commit_shas
    references = uses_references(YAML.safe_load(workflow, aliases: true))

    assert_predicate references, :any?
    references.each do |reference|
      next if reference.start_with?('./')

      assert_match(%r{\A[^@]+@[0-9a-f]{40}\z}, reference)
    end
  end

  def test_pinning_scan_includes_step_and_job_level_uses
    parsed = YAML.safe_load(<<~YAML)
      jobs:
        build:
          steps:
            - uses: owner/action@#{'a' * 40}
        delegated:
          uses: owner/workflows/.github/workflows/test.yml@#{'b' * 40}
    YAML

    assert_equal [
      "owner/action@#{'a' * 40}",
      "owner/workflows/.github/workflows/test.yml@#{'b' * 40}"
    ], uses_references(parsed)
  end

  def test_redis_runtime_coverage_is_not_opt_in
    refute_includes runtime_test, 'REDIS_INTEGRATION'
    refute_includes runtime_test, 'skip '
    assert_includes runtime_test, '@namespaced_redis.ping'
  end

private
  def workflow
    @workflow ||= Rails.root.join('.github/workflows/test.yml').read
  end

  def runtime_test
    @runtime_test ||= Rails.root.join(
      'test/integration/resque_runtime_test.rb'
    ).read
  end

  def uses_references(value)
    case value
    when Hash
      value.flat_map do |key, child|
        key == 'uses' ? [child] : uses_references(child)
      end
    when Array
      value.flat_map { |child| uses_references(child) }
    else
      []
    end
  end
end
