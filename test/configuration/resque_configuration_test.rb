require 'test_helper'

class ResqueConfigurationTest < ActiveSupport::TestCase
  FakeResque = Struct.new(:redis)

  class FakeRedis
    class << self
      attr_reader :options

      def connect(options)
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

    assert_equal({url: 'redis://redis.example.test:6380/9', thread_safe: true}, FakeRedis.options)
    assert_equal 'isolated', namespaced_client.name
    assert_equal({redis: :redis_client}, namespaced_client.options)
    assert_same namespaced_client, resque.redis
  end
end
