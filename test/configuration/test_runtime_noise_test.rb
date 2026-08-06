require 'test_helper'

class TestRuntimeNoiseTest < Minitest::Test
  def test_rails_7_1_defaults_are_loaded
    assert_equal '7.1.6', Rails.version
    assert_equal 7.1, Rails.application.config.loaded_config_version
    assert Rails.application.config.action_controller.raise_on_open_redirects
    assert_equal :json, Rails.application.config.action_dispatch.cookies_serializer
    assert_equal :none, Rails.application.config.action_dispatch.show_exceptions
  end

  def test_rails_7_1_runtime_defaults_are_active
    config = Rails.application.config

    refute config.add_autoload_paths_to_load_path
    assert config.precompile_filter_parameters
    assert_equal :html5, config.dom_testing_default_html_version
    assert_equal 100.megabytes, config.log_file_size
    assert_equal :error, config.action_dispatch.debug_exception_log_level
    assert_equal '0', config.action_dispatch.default_headers['X-XSS-Protection']
    assert_equal false, config.action_controller.allow_deprecated_parameters_hash_equality
    assert_equal Rails::HTML5::Sanitizer,
      ActionView::Helpers::SanitizeHelper.sanitizer_vendor
  end

  def test_rails_7_1_active_support_formats_are_active
    assert_equal 7.1, ActiveSupport.cache_format_version
    assert_equal :json_allow_marshal,
      ActiveSupport::Messages::Codec.default_serializer
    assert ActiveSupport::Messages::Metadata.use_message_serializer_for_metadata
    assert Rails.application.config.active_support.raise_on_invalid_cache_expiration_time
  end

  def test_json_message_serializer_can_read_legacy_marshal_payloads
    secret = SecureRandom.random_bytes(ActiveSupport::MessageEncryptor.key_len)
    legacy = ActiveSupport::MessageEncryptor.new(secret, serializer: :marshal)
    current = ActiveSupport::MessageEncryptor.new(
      secret,
      serializer: :json_allow_marshal
    )
    payload = {'admin_signed_in' => true}

    assert_equal payload, current.decrypt_and_verify(legacy.encrypt_and_sign(payload))
  end

  def test_rails_7_1_active_record_defaults_are_active
    config = Rails.application.config.active_record

    refute config.run_commit_callbacks_on_first_saved_instances_in_transaction
    assert config.commit_transaction_on_non_local_return
    refute config.allow_deprecated_singular_associations_name
    assert config.sqlite3_adapter_strict_strings_by_default
    assert config.raise_on_assign_to_attr_readonly
    refute config.belongs_to_required_validates_foreign_key
    assert config.before_committed_on_all_records
    assert_nil config.default_column_serializer
    assert_equal 7.1, config.marshalling_format_version
    assert config.run_after_transaction_callbacks_in_order_defined
    assert_equal :initialize, config.generate_secure_token_on
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
