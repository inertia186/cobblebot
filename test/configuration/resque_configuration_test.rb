require 'test_helper'
require 'open3'
require 'rake'

class ResqueConfigurationTest < ActiveSupport::TestCase
  FakeResque = Struct.new(:redis)

  class FakeRedis
    class << self
      attr_reader :options

      def new(options)
        @options = options
        :redis_client
      end
    end
  end

  class FakeNamespace
    attr_reader :name, :options

    def initialize(name, options)
      @name = name
      @options = options
    end
  end

  def test_operational_environments_default_to_database_one
    %w[development beta production].each do |environment|
      configuration = ResqueConfiguration.load(environment: environment, env: {})

      assert_equal 'redis://localhost:6379/1', configuration.redis_url
      assert_equal 'resque', configuration.namespace
    end
  end

  def test_test_environment_defaults_to_database_three
    configuration = ResqueConfiguration.load(environment: 'test', env: {})

    assert_equal 'redis://localhost:6379/3', configuration.redis_url
    assert_equal 'resque', configuration.namespace
  end

  def test_environment_overrides_url_and_namespace
    configuration = ResqueConfiguration.load(
      environment: 'test',
      env: {
        'COBBLEBOT_REDIS_URL' => 'redis://redis.example.test:6380/9',
        'COBBLEBOT_RESQUE_NAMESPACE' => 'isolated'
      }
    )

    assert_equal 'redis://redis.example.test:6380/9', configuration.redis_url
    assert_equal 'isolated', configuration.namespace
  end

  def test_apply_builds_a_lazy_namespaced_client
    configuration = ResqueConfiguration.new(
      redis_url: 'redis://redis.example.test:6380/9',
      namespace: 'isolated'
    )
    resque = FakeResque.new

    namespaced_client = configuration.apply(
      resque: resque,
      redis: FakeRedis,
      namespace_class: FakeNamespace
    )

    assert_equal({url: 'redis://redis.example.test:6380/9', protocol: 3}, FakeRedis.options)
    assert_equal 'isolated', namespaced_client.name
    assert_equal({redis: :redis_client}, namespaced_client.options)
    assert_same namespaced_client, resque.redis
  end

  def test_supported_resque_tasks_are_loaded_without_the_retired_pool_hook
    output, errors, status = Open3.capture3(
      {'RAILS_ENV' => 'test'},
      'bundle', 'exec', 'rake', '-P',
      chdir: Rails.root.to_s
    )

    assert status.success?, errors
    assert_includes output, 'rake resque:work'
    assert_includes output, 'rake resque:scheduler'
    refute_includes output, 'rake resque:pool:setup'
  end

  def test_resque_serialization_uses_the_current_multi_json_api
    payload = {'class' => 'ExampleWorker', 'args' => [{'value' => 1}]}

    _output, errors = capture_io do
      assert_equal payload, Resque.decode(Resque.encode(payload))
    end

    assert_empty errors
    assert_raises Resque::Helpers::DecodeException do
      Resque.decode('{invalid json')
    end
  end
end
