require 'test_helper'

class EnvironmentConfigurationTest < ActiveSupport::TestCase
  def test_test_environment_uses_the_current_static_file_server_api
    config = Rails.application.config.public_file_server

    assert config.enabled
    assert_equal 'public, max-age=3600', config.headers['cache-control']
  end

  def test_production_static_file_server_follows_the_documented_environment_flag
    source = Rails.root.join('config/environments/production.rb').read

    assert_includes source,
      "config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?"
    refute_includes source, 'config.serve_static_files'
  end
end
