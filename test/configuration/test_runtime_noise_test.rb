require 'test_helper'

class TestRuntimeNoiseTest < Minitest::Test
  def test_minitest_6_and_extracted_mock_runtime_are_loaded
    assert_equal '6.0.6', Minitest::VERSION
    assert defined?(Minitest::Mock)
  end

  def test_rails_8_1_framework_and_defaults_are_loaded
    assert_equal '3.3.12', RUBY_VERSION
    assert_equal '8.1.3.1', Rails.version
    assert_equal 8.1, Rails.application.config.loaded_config_version
    zoned_time = Time.new(2026, 1, 1, 12, 0, 0, '+05:30')
    assert_equal zoned_time.utc_offset, zoned_time.to_time.utc_offset
    assert Rails.application.config.action_dispatch.strict_freshness
    assert_equal 1, Regexp.timeout
    assert_equal :raise, Rails.application.config.action_controller.action_on_open_redirect
    assert_equal :raise, Rails.application.config.action_controller.action_on_path_relative_redirect
    refute Rails.application.config.action_controller.escape_json_responses
    refute Rails.application.config.active_support.escape_js_separators_in_json
    assert Rails.application.config.active_record.raise_on_missing_required_finder_order_columns
    assert_equal :ruby, Rails.application.config.action_view.render_tracker
    assert Rails.application.config.action_view.remove_hidden_field_autocomplete
    assert_equal :json, Rails.application.config.action_dispatch.cookies_serializer
    assert_equal :none, Rails.application.config.action_dispatch.show_exceptions
  end

  def test_rails_8_1_json_and_hidden_field_behavior
    json = ActionController::Base.renderer.render(json: { value: "<\u2028" })
    assert_equal "{\"value\":\"<\u2028\"}", json

    hidden = ActionController::Base.helpers.hidden_field_tag(:filter, 'all')
    refute_includes hidden, 'autocomplete='
  end

  def test_rails_8_1_finder_order_requirement_has_application_primary_keys
    application_tables = ActiveRecord::Base.connection.tables - %w(ar_internal_metadata schema_migrations)
    assert application_tables.all? { |table| ActiveRecord::Base.connection.primary_key(table).present? },
      'all application tables need a primary key for order-dependent finders'
  end

  def test_rails_7_2_runtime_defaults_are_active
    config = Rails.application.config

    refute config.yjit
    assert config.active_record.postgresql_adapter_decode_dates
    assert config.active_record.validate_migration_timestamps
    refute config.respond_to?(:active_job)
    refute config.respond_to?(:active_storage)
  end

  def test_postgresql_adapter_decodes_dates
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      value = ActiveRecord::Base.connection.select_value("SELECT DATE '2026-08-05'")
      assert_instance_of Date, value
      assert_equal Date.new(2026, 8, 5), value
    else
      assert Rails.application.config.active_record.postgresql_adapter_decode_dates
    end
  end

  def test_rails_7_1_runtime_defaults_are_active
    config = Rails.application.config

    refute config.add_autoload_paths_to_load_path
    assert config.precompile_filter_parameters
    assert_equal :html5, config.dom_testing_default_html_version
    assert_equal 100.megabytes, config.log_file_size
    assert_equal :error, config.action_dispatch.debug_exception_log_level
    assert_equal '0', config.action_dispatch.default_headers['X-XSS-Protection']
    refute_equal({'value' => 1}, ActionController::Parameters.new(value: 1))
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

  def test_disabled_rack_mini_profiler_surface_is_retired
    refute defined?(Rack::MiniProfiler)
    refute File.exist?(Rails.root.join('config/initializers/rack_profiler.rb'))
    refute_includes File.read(Rails.root.join('Gemfile.lock')), 'rack-mini-profiler'
  end

  def test_simplecov_uses_an_explicit_suite_name
    assert_equal 'Rails Tests', SimpleCov.command_name
  end

  def test_focused_runs_keep_coverage_merging_without_a_floor
    return if ENV['COBBLEBOT_COVERAGE_GATE'] == '1'

    assert SimpleCov.merging
    assert_empty SimpleCov.minimum_coverage
  end

  def test_coverage_gate_is_unmerged_and_requires_75_percent
    return unless ENV['COBBLEBOT_COVERAGE_GATE'] == '1'

    refute SimpleCov.merging
    assert_equal({line: 75}, SimpleCov.minimum_coverage)
  end
end
