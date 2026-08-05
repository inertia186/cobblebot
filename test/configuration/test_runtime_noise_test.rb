require 'test_helper'

class TestRuntimeNoiseTest < Minitest::Test
  def test_rails_7_defaults_are_loaded
    assert_equal '7.1.6', Rails.version
    assert_equal 7.0, Rails.application.config.loaded_config_version
    assert Rails.application.config.action_controller.raise_on_open_redirects
    assert_equal :json, Rails.application.config.action_dispatch.cookies_serializer
    assert_equal :none, Rails.application.config.action_dispatch.show_exceptions
  end

  def test_active_support_deprecations_raise
    assert_equal :raise, Rails.application.config.active_support.deprecation
  end

  def test_simplecov_uses_an_explicit_suite_name
    assert_equal 'Rails Tests', SimpleCov.command_name
  end

  def test_focused_runs_keep_coverage_merging_without_a_floor
    return if ENV['COBBLEBOT_COVERAGE_GATE'] == '1'

    assert SimpleCov.use_merging
    assert_empty SimpleCov.minimum_coverage
  end

  def test_coverage_gate_is_unmerged_and_requires_75_percent
    return unless ENV['COBBLEBOT_COVERAGE_GATE'] == '1'

    refute SimpleCov.use_merging
    assert_equal({line: 75}, SimpleCov.minimum_coverage)
  end
end
